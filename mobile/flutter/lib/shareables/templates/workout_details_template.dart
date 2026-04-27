import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

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
    // Captures get clipped beyond ~10 exercises on portrait/story aspect —
    // collapse the long tail into a "+ N more" footer.
    final visible = exercises.take(10).toList();
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
                child: ListView.separated(
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
                maxLines: 1,
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
                  // Render bodyweight sets as "BW" instead of "—" / "0 lbs"
                  // so the shared image matches what the user actually did.
                  final isBodyweight = s.weight == null || s.weight == 0;
                  final weightStr = isBodyweight
                      ? 'BW'
                      : '${s.weight!.toStringAsFixed(s.weight! == s.weight!.roundToDouble() ? 0 : 1)} ${s.unit}';
                  // If reps is 0 (data not logged), show "—" instead of "0 reps"
                  final repsStr = s.reps > 0 ? '${s.reps} reps' : '— reps';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
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
