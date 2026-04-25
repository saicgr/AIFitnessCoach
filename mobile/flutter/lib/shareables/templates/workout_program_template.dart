import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// Workout Program — Hevy-style multi-day program summary. Renders the
/// exercise list (no per-set breakdown) with thumbnail icons + sets·reps
/// summary line.
class WorkoutProgramTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WorkoutProgramTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final exercises = (data.exercises ?? const <ShareableExercise>[]);
    final visible = exercises.take(14).toList();
    final overflow = exercises.length - visible.length;

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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showWatermark)
                    FitWizWatermark(
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
                  fontSize: 22 * mul,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111111),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) => _ProgramRow(ex: visible[i]),
                ),
              ),
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ $overflow more',
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

class _ProgramRow extends StatelessWidget {
  final ShareableExercise ex;
  const _ProgramRow({required this.ex});

  @override
  Widget build(BuildContext context) {
    final setCount = ex.sets.length;
    final reps = ex.sets.isEmpty ? null : ex.sets.first.reps;
    final summary =
        setCount == 0 ? null : '$setCount sets · ${reps ?? '–'} reps';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE9ECEF),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: ex.imageUrl != null
              ? Image.network(
                  ex.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFF888888),
                    size: 18,
                  ),
                )
              : const Icon(
                  Icons.fitness_center_rounded,
                  color: Color(0xFF888888),
                  size: 18,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ex.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              if (summary != null)
                Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
