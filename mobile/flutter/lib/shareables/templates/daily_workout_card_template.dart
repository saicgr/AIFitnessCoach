import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// Single-day workout card for `weeklyPlan` / `monthlyPlan` shares with
/// `planDays.length == 1`, plus the existing `workoutComplete` payload shape.
///
/// Mirrors the white-card-on-tinted-canvas look of [WorkoutDetailsTemplate]
/// but renders smaller exercise illustration thumbs, the user's @ handle,
/// and a zealova.com share link footer so screenshots double as ads.
class DailyWorkoutCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const DailyWorkoutCardTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  List<ShareableExercise> _resolveExercises() {
    if (data.exercises != null && data.exercises!.isNotEmpty) {
      return data.exercises!;
    }
    final days = data.planDays;
    if (days != null && days.length == 1) {
      return days.first.exercises;
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final exercises = _resolveExercises();
    final visible = exercises.take(10).toList();
    final overflow = exercises.length - visible.length;
    final user = data.userDisplayName?.trim();
    final url = data.deepLinkUrl;

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: data.accentColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
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
                    const AppWatermark(
                      textColor: Color(0xFF111111),
                      iconSize: 20,
                      fontSize: 13,
                    ),
                  const Spacer(),
                  if (user != null && user.isNotEmpty)
                    Text(
                      '@$user',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF666666),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 28 * mul,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: const Color(0xFF111111),
                ),
              ),
              if (data.periodLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  data.periodLabel,
                  style: TextStyle(
                    fontSize: 12 * mul,
                    color: const Color(0xFF7A7A7A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: data.highlights
                    .where((h) => h.isPopulated)
                    .take(4)
                    .map(
                      (h) => _StatChip(
                        label: h.label.toUpperCase(),
                        value: h.value,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length + (overflow > 0 ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(
                    height: 14,
                    color: Color(0xFFEEEEEE),
                  ),
                  itemBuilder: (_, i) {
                    if (i >= visible.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '+ $overflow more',
                          style: TextStyle(
                            fontSize: 12 * mul,
                            color: const Color(0xFF999999),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return _ExerciseRow(ex: visible[i], mul: mul);
                  },
                ),
              ),
              if (url != null && url.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    url.replaceFirst(RegExp(r'^https?://'), ''),
                    style: TextStyle(
                      fontSize: 10 * mul,
                      color: const Color(0xFF999999),
                      fontWeight: FontWeight.w600,
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111111),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ShareableExercise ex;
  final double mul;

  const _ExerciseRow({required this.ex, required this.mul});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExerciseThumb(imageUrl: ex.imageUrl, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ex.name,
                style: TextStyle(
                  fontSize: 13 * mul,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111111),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (ex.sets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _formatSets(ex.sets),
                    style: TextStyle(
                      fontSize: 11 * mul,
                      color: const Color(0xFF666666),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSets(List<ShareableSet> sets) {
    if (sets.isEmpty) return '';
    final first = sets.first;
    final w = first.weight;
    final reps = first.reps;
    if (w != null && w > 0) {
      return '${sets.length} sets · ${w.toStringAsFixed(0)} ${first.unit} × $reps reps';
    }
    return '${sets.length} sets · $reps reps';
  }
}

class _ExerciseThumb extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _ExerciseThumb({required this.imageUrl, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('🏋️', style: TextStyle(fontSize: 14)),
              ),
              loadingBuilder: (ctx, child, prog) {
                if (prog == null) return child;
                return const ColoredBox(color: Color(0xFFE5E5E5));
              },
            )
          : const Center(child: Text('🏋️', style: TextStyle(fontSize: 14))),
    );
  }
}
