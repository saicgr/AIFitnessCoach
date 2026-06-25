import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/workout_program_context.dart';

/// Compact "Week X · {Program Name}" banner shown when a workout came from an
/// enrolled program. Renders the program provenance the backend tags onto
/// program-sourced workouts (via [WorkoutProgramContext]).
///
/// Used by the active-workout screen header (both Easy + Advanced modes) and
/// available for any other surface that wants to show program context. Renders
/// nothing when [context_] is null / empty, so callers can drop it in
/// unconditionally.
class ProgramContextBanner extends ConsumerWidget {
  final WorkoutProgramContext? programContext;

  /// Compact variant: thinner padding, smaller text — for dense headers.
  final bool compact;

  const ProgramContextBanner({
    super.key,
    required this.programContext,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pc = programContext;
    if (pc == null || !pc.hasContent) return const SizedBox.shrink();

    final tc = ThemeColors.of(context);
    // The accent is the ONE place program chrome may use the reserved warm hue
    // (routed through ThemeColors → AccentColorScope, never hardcoded).
    final accent = tc.accent;
    final banner = pc.banner();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pc.isAddon ? Icons.add_circle_outline : Icons.calendar_view_week,
            size: compact ? 13 : 15,
            color: accent,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              pc.isAddon ? 'Add-on · $banner' : banner,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: tc.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
