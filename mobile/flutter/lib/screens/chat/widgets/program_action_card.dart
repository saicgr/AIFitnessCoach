import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/program_assignments_provider.dart';
import '../../../data/services/haptic_service.dart';

/// In-chat card for the coach's program actions:
///   • `recommend_program` — the coach suggests a program → View program
///   • `assign_program`     — the coach started a program for you → My Programs
///   • `create_program`     — the coach drafted a program → Open builder / My Programs
///
/// Mirrors the existing chat action-card pattern (e.g. [ChatActionConfirmCard],
/// [RecommendedMealCard]): a single bordered card with an icon, a summary line,
/// and one or two CTAs that deep-link into the Program Library / builder /
/// My Programs. The coach has already performed any mutation server-side; this
/// card is a confirmation + deep-link, not a mutation surface — so on
/// assign/create we refresh the assignments provider so "My Programs" reflects
/// the new enrollment immediately.
class ProgramActionCard extends ConsumerWidget {
  final Map<String, dynamic> actionData;
  const ProgramActionCard({super.key, required this.actionData});

  /// The action types this card handles.
  static const Set<String> handledActions = {
    'recommend_program',
    'assign_program',
    'create_program',
  };

  String get _action => (actionData['action'] as String?) ?? '';
  String? get _templateId => actionData['template_id']?.toString();

  /// The library card id — plain curated id or `branded:<uuid>`. Passed verbatim
  /// on the deep-link; the Program Library screen handles both forms and
  /// auto-opens the rich detail sheet.
  String? get _programId => actionData['program_id']?.toString();

  String get _programName =>
      (actionData['program_name'] as String?)?.trim().isNotEmpty == true
          ? actionData['program_name'] as String
          : 'this program';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;

    final (IconData icon, String summary, _ProgramCta primaryCta) = switch (
        _action) {
      'assign_program' => (
          Icons.check_circle_outline,
          'Started "$_programName" for you.',
          _ProgramCta(
            label: 'View in My Programs',
            onTap: () => _goMyPrograms(context, ref),
          ),
        ),
      'create_program' => (
          Icons.auto_awesome,
          'Drafted "$_programName".',
          _ProgramCta(
            label: _templateId != null ? 'Open program' : 'View in My Programs',
            onTap: () => _openCreated(context, ref),
          ),
        ),
      _ => (
          // recommend_program (default)
          Icons.recommend_outlined,
          'Recommended: "$_programName".',
          _ProgramCta(
            label: 'View program',
            onTap: () => _viewProgram(context),
          ),
        ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: primaryCta.onTap,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: Text(primaryCta.label),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Recommend → deep-link the Program Library straight to this program's rich
  /// detail sheet. The id is passed verbatim (plain curated id or
  /// `branded:<uuid>` — the screen handles both). Falls back to the gallery when
  /// the coach didn't include a program id.
  void _viewProgram(BuildContext context) {
    HapticService.selection();
    final id = _programId;
    if (id != null && id.isNotEmpty) {
      context.push(
        '/workout/program-library?programId=${Uri.encodeComponent(id)}',
      );
    } else {
      context.push('/workout/program-library');
    }
  }

  /// Assign → the coach already enrolled the user; refresh + show My Programs.
  void _goMyPrograms(BuildContext context, WidgetRef ref) {
    HapticService.selection();
    // The coach mutated server-side — pull the new enrollment in.
    refreshProgramAssignmentsW(ref);
    // My Programs lives on Home (and Profile). Route to Home so the card shows.
    context.go('/home');
  }

  /// Create → if a template id is present, open the builder; otherwise My
  /// Programs (the draft surfaces there once scheduled).
  void _openCreated(BuildContext context, WidgetRef ref) {
    HapticService.selection();
    refreshProgramAssignmentsW(ref);
    if (_templateId != null) {
      context.push('/workout/program-builder');
    } else {
      context.go('/home');
    }
  }
}

class _ProgramCta {
  final String label;
  final VoidCallback onTap;
  const _ProgramCta({required this.label, required this.onTap});
}
