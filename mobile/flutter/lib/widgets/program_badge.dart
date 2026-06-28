import 'package:flutter/material.dart';

import '../data/models/workout.dart';
import '../data/models/workout_program_context.dart';
import '../screens/schedule/widgets/program_color.dart';

/// Program attribution for a workout — which program it belongs to and the
/// color used to represent that program consistently across the app (the same
/// hashing the merged schedule uses, so HYROX is the same color on the hero,
/// the schedule chip and the Manage row).
///
/// [isAi] is true when the workout has no enrolled-program provenance (the
/// always-on AI program is the default source for any workout that isn't from a
/// curated/branded program).
({String name, Color color, bool isAi}) workoutProgramAttribution(Workout w) {
  final pc = w.programContext;
  final name = pc?.programName?.trim();
  if (name != null && name.isNotEmpty) {
    return (
      name: name,
      color: ProgramColors.forKey(pc!.assignmentId ?? pc.programId),
      isAi: false,
    );
  }
  return (name: 'AI Program', color: ProgramColors.ai, isAi: true);
}

/// A compact, glanceable pill naming the workout's program — designed to sit
/// over the hero card's photo scrim (white text + colored marker on a dark
/// translucent pill). For curated programs it shows the program name in that
/// program's color; for AI-generated workouts it shows "AI Program" with a
/// sparkle in the AI cyan.
class ProgramBadge extends StatelessWidget {
  final Workout workout;

  const ProgramBadge({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final attr = workoutProgramAttribution(workout);
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 12, 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: attr.color.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attr.isAi ? Icons.auto_awesome_rounded : Icons.circle,
            size: attr.isAi ? 12 : 8,
            color: attr.color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attr.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
