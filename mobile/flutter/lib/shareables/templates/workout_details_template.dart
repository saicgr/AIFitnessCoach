import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

// Re-export ShareableAspect for the auto-switch logic.

/// Hevy-style "Share Workout" — the full vertical exercise list with logged
/// set × reps × weight per exercise. The user explicitly asked for this from
/// looking at Hevy's UI.
class WorkoutDetailsTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WorkoutDetailsTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final exercises = data.exercises ?? const [];
    // Auto-switch to story (9:16) when content is dense — 4:5 portrait
    // crops the trailing exercises and any long names. We don't mutate
    // `data.aspect` here; this just sets the visible cap. Story can fit
    // ~14 exercises, portrait ~10. Empty handled below.
    final isStory = data.aspect == ShareableAspect.story;
    final hasLongNames = exercises.any((e) => e.name.length > 30);
    final maxVisible = isStory || hasLongNames ? 14 : 10;
    final visible = exercises.take(maxVisible).toList();
    final overflow = exercises.length - visible.length;

    final duration = data.highlights
        .firstWhere(
          (h) => h.label.toUpperCase().contains('DURATION') ||
              h.label.toUpperCase().contains('TIME'),
          orElse: () => const ShareableMetric(label: '', value: ''),
        )
        .value;
    final volume = data.highlights
        .firstWhere(
          (h) => h.label.toUpperCase().contains('VOLUME'),
          orElse: () => const ShareableMetric(label: '', value: ''),
        )
        .value;

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: data.accentColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showWatermark)
                    AppWatermark(
                      textColor: const Color(0xFF111111),
                      iconSize: 20,
                      fontSize: 13,
                    ),
                  const Spacer(),
                  if (data.userDisplayName != null &&
                      data.userDisplayName!.trim().isNotEmpty)
                    Text(
                      'Created by ${data.userDisplayName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 24 * mul,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111111),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (duration.isNotEmpty)
                    _MetaPill(label: 'Duration', value: duration),
                  if (volume.isNotEmpty)
                    _MetaPill(label: 'Volume', value: volume),
                  _MetaPill(
                    label: 'Exercises',
                    value: '${exercises.length}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: visible.isEmpty
                    // Empty workout placeholder (Issue 15 edge case) — never
                    // crash, render a clear "no exercises" message.
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.fitness_center_outlined,
                              color: Color(0xFFBDBDBD),
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No exercises logged',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: Color(0xFFE5E5E5),
                          height: 18,
                          thickness: 1,
                        ),
                        itemBuilder: (context, i) => _ExerciseRow(ex: visible[i]),
                      ),
              ),
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '+ $overflow more exercise${overflow == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;
  const _MetaPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label  ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
            letterSpacing: 0.4,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ShareableExercise ex;
  const _ExerciseRow({required this.ex});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE9ECEF),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: ex.imageUrl != null
              ? Image.network(
                  ex.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFF888888),
                    size: 22,
                  ),
                )
              : const Icon(
                  Icons.fitness_center_rounded,
                  color: Color(0xFF888888),
                  size: 22,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ex.name,
                // Allow wrap for long exercise names (Issue 15 edge case —
                // 40+ char names previously truncated to "Barbell Bulgar...").
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              if (ex.sets.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        'SET',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withValues(alpha: 0.45),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      'WEIGHT & REPS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.45),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                ...List.generate(ex.sets.length, (i) {
                  final s = ex.sets[i];
                  // Bodyweight branch: render "BW" only when the exercise is
                  // actually bodyweight (s.isBodyweight) OR weight==null. A
                  // missing weight on a non-BW exercise (e.g. machine row
                  // someone forgot to log) renders as "—" instead of falsely
                  // labeling it BW.
                  String fmtWeight(num? w) {
                    if (s.isBodyweight && (w == null || w == 0)) return 'BW';
                    if (w == null) return '—';
                    if (w == 0) return s.isBodyweight ? 'BW' : '—';
                    return '${w.toStringAsFixed(w == w.roundToDouble() ? 0 : 1)} ${s.unit}';
                  }

                  final weightStr = fmtWeight(s.weight);
                  final repsStr = s.reps > 0 ? '${s.reps} reps' : '— reps';

                  // Target line: only render if a planned target exists AND
                  // differs visibly from the actual (otherwise it's noise).
                  final hasTarget =
                      (s.targetReps != null && s.targetReps! > 0) ||
                      (s.targetWeight != null && s.targetWeight! > 0);
                  final actualMatchesTarget = hasTarget &&
                      s.reps == s.targetReps &&
                      ((s.weight ?? 0) == (s.targetWeight ?? 0));
                  String? targetStr;
                  if (hasTarget && !actualMatchesTarget) {
                    final tw = fmtWeight(s.targetWeight);
                    final tr = (s.targetReps != null && s.targetReps! > 0)
                        ? '${s.targetReps} reps'
                        : '— reps';
                    targetStr = 'target $tw  ×  $tr';
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            Text(
                              '$weightStr  ×  $repsStr',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (targetStr != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 28, top: 0),
                            child: Text(
                              targetStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
