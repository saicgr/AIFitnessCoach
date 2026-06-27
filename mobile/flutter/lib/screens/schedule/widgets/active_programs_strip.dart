import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/user_program_assignment.dart';
import 'program_color.dart';

/// "ACTIVE PROGRAMS · N" strip above the agenda — a color chip per enrolled
/// program plus a "⚙ Manage" action. Mirrors screen A of the v9 mockup. Only
/// shown when there's at least one active assignment.
class ActiveProgramsStrip extends StatelessWidget {
  final List<UserProgramAssignment> assignments;
  final ThemeColors colors;
  final VoidCallback onManage;
  final ValueChanged<UserProgramAssignment> onTapProgram;

  const ActiveProgramsStrip({
    super.key,
    required this.assignments,
    required this.colors,
    required this.onManage,
    required this.onTapProgram,
  });

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'ACTIVE PROGRAMS · ${assignments.length}',
                  style: ZType.lbl(
                    11,
                    color: colors.textMuted,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onManage,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, size: 14, color: colors.cyan),
                    const SizedBox(width: 4),
                    Text(
                      'Manage',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: assignments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final a = assignments[i];
              return _ProgramChip(
                assignment: a,
                color: ProgramColors.forKey(a.id),
                colors: colors,
                onTap: () => onTapProgram(a),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProgramChip extends StatelessWidget {
  final UserProgramAssignment assignment;
  final Color color;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _ProgramChip({
    required this.assignment,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAddon = assignment.isAddon;
    final total = assignment.durationWeeks;
    final wk = total != null && total > 0
        ? 'W${assignment.currentWeek}/$total'
        : 'W${assignment.currentWeek}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAddon)
              Text(
                '+ ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Text(
              assignment.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            if (!isAddon) ...[
              const SizedBox(width: 6),
              Text(
                wk,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
