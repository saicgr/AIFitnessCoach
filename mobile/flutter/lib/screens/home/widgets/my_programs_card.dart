import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/user_program_assignment.dart';
import '../../../data/providers/program_assignments_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/design_system/section_header.dart';
import '../../workout/widgets/ai_adaptive_plan_card.dart';
import '../../workout/widgets/program_manage_sheet.dart';

/// "My Programs" — lists the user's active program enrollments with progress,
/// the weekdays each occupies, and a primary/add-on badge. Tapping an item
/// opens a manage sheet (rename, change days, change slot, pause/resume, end).
///
/// Mounted on the home screen (and reusable on profile). Self-hides to zero
/// height while loading with no cached value AND when the user has no
/// assignments — except it always renders the empty-state card once loaded so
/// the user has a discovery path into the Program Library. Wired to
/// [programAssignmentsProvider] (cache-first + keepAlive); mutations refresh
/// both that provider and the today provider so the hero stays in lock-step.
class MyProgramsCard extends ConsumerWidget {
  /// When true, the section header is omitted (caller supplies its own, e.g.
  /// the profile TRAINING section). Defaults to showing the header.
  final bool showHeader;

  const MyProgramsCard({
    super.key,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(programAssignmentsProvider);

    return async.when(
      // Cache-first keepAlive means a returning user paints instantly; a true
      // cold load shows nothing (no skeleton flash) — the hero carousel is the
      // primary surface, this is a secondary section.
      loading: () => const SizedBox.shrink(),
      error: (e, _) => _ErrorRow(
        onRetry: () => refreshProgramAssignmentsW(ref),
        showHeader: showHeader,
      ),
      data: (assignments) {
        final active =
            assignments.where((a) => a.status != 'completed').toList();
        // The current training plan = active PRIMARY program(s). When there's
        // none, the user is on the default AI-decides adaptive plan — show the
        // synthetic "AI Coach · Adaptive Plan" card as the active plan (never an
        // empty state, because AI-decides is a real, active plan). An add-on
        // without a primary still gets the AI card (it owns the primary slot).
        final hasActivePrimary =
            active.any((a) => a.isPrimary && a.isActive);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHeader) const SectionHeader(label: 'My Programs'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // AI-decides adaptive plan as the active card when no primary
                  // program is enrolled.
                  if (!hasActivePrimary) ...[
                    const AiAdaptivePlanCard(),
                    const SizedBox(height: 4),
                    // Gentle invitation into the library — the adaptive plan is a
                    // real active plan, so this is an offer to explore, not an
                    // empty-state takeover.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          HapticService.selection();
                          context.push('/workout/program-library');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: ThemeColors.of(context).accent,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Browse programs →',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (final a in active) ...[
                    _ProgramRow(assignment: a),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final VoidCallback onRetry;
  final bool showHeader;
  const _ErrorRow({required this.onRetry, required this.showHeader});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) const SectionHeader(label: 'My Programs'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tc.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tc.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, size: 18, color: tc.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Couldn't load your programs.",
                    style: TextStyle(fontSize: 13, color: tc.textSecondary),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One enrolled program — title, "Week X of Y", % complete, the weekdays it
/// occupies, and a primary/add-on badge. Tap → manage sheet.
class _ProgramRow extends ConsumerWidget {
  final UserProgramAssignment assignment;
  const _ProgramRow({required this.assignment});

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final a = assignment;
    final paused = a.status == 'paused';
    final pct = (a.progressPercentage).clamp(0, 100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticService.selection();
          showProgramManageSheet(context, ref, a);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tc.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: tc.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: a.isAddon ? 'ADD-ON' : 'PRIMARY',
                    color: a.isAddon ? tc.textMuted : accent,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    paused ? 'Paused · ${a.progressLabel}' : a.progressLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: tc.textSecondary,
                    ),
                  ),
                  if (pct > 0) ...[
                    Text('  ·  ',
                        style: TextStyle(fontSize: 12.5, color: tc.textMuted)),
                    Text('$pct% complete',
                        style:
                            TextStyle(fontSize: 12.5, color: tc.textSecondary)),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // % complete progress bar.
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 5,
                  backgroundColor: tc.elevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    paused ? tc.textMuted : accent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Weekday dots the program occupies.
              Row(
                children: [
                  for (int i = 0; i < 7; i++) ...[
                    _DayDot(
                      letter: _dayLetters[i],
                      filled: a.coversWeekday(i),
                      accent: accent,
                    ),
                    if (i < 6) const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  Icon(Icons.tune_rounded, size: 16, color: tc.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String letter;
  final bool filled;
  final Color accent;
  const _DayDot(
      {required this.letter, required this.filled, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? accent : Colors.transparent,
        border: Border.all(
          color: filled ? accent : tc.cardBorder,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? tc.accentContrast : tc.textMuted,
        ),
      ),
    );
  }
}
