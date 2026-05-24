/// Suggested reply chips rendered below a coach turn that was seeded from
/// a home-screen card (coach hero, workout card, etc.). Plan §1c.5.
///
/// Each chip either:
///   * Sends the chip's literal label as a new user turn (default), or
///   * Fires a workout-card `action_data.kind` (§1c.2) via [onActionTap].
///
/// The chip strip is intentionally a dumb presentational widget — the
/// chat screen owns the wiring (it has the GoRouter + Riverpod refs to
/// dispatch the actions). Reusing the existing chat-bubble layout keeps
/// the visual consistency the founder asked for in §1c.5 ("not two
/// parallel systems").
library;

import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';

/// One suggested-reply chip definition.
///
/// Pick exactly one of [actionKind] (fires a workout-card action via the
/// chat notifier) or default to sending [label] as a user-typed message.
class SuggestedReplyChip {
  /// Visible chip text — also sent as user turn when [actionKind] is null.
  final String label;

  /// Optional `action_data.kind` to dispatch instead of sending the label
  /// as a user message. See §1c.2 for the full kind vocabulary.
  final String? actionKind;

  /// Optional structured payload merged into the action_data when fired.
  /// Lets callers pass workout_id / variant_id / etc. through.
  final Map<String, dynamic>? actionPayload;

  /// Optional explicit GoRouter route. Wins over [actionKind] when set —
  /// useful for chips that just deep-link without changing app state.
  final String? route;

  const SuggestedReplyChip({
    required this.label,
    this.actionKind,
    this.actionPayload,
    this.route,
  });
}

/// Resolves the chip list for a workout-card mode. Per the §1c.5 mapping:
///   * windDown          → Move to tomorrow · Why? · I'll do it tonight anyway
///   * recoveryLighter   → Switch to lighter · Why? · Keep planned
///   * preWorkoutFuelGap → Log a snack · Why? · Start anyway
///   * (generic)         → Why? · What's next? · Quick check
///
/// [extraPayload] is merged into every action-bearing chip — pass
/// `{'workout_id': '...'}` to scope an action to a specific workout.
List<SuggestedReplyChip> chipsForWorkoutMode(
  String? mode, {
  Map<String, dynamic>? extraPayload,
}) {
  Map<String, dynamic> p([Map<String, dynamic>? extra]) {
    return {
      ...?extraPayload,
      ...?extra,
    };
  }

  switch (mode) {
    case 'windDown':
      return [
        SuggestedReplyChip(
          label: 'Move to tomorrow',
          actionKind: 'reschedule_to_tomorrow',
          actionPayload: p(),
        ),
        const SuggestedReplyChip(label: 'Why?'),
        const SuggestedReplyChip(label: "I'll do it tonight anyway"),
      ];
    case 'recoveryLighter':
      return [
        SuggestedReplyChip(
          label: 'Switch to lighter',
          actionKind: 'swap_to_lighter_variant',
          actionPayload: p(),
        ),
        const SuggestedReplyChip(label: 'Why?'),
        const SuggestedReplyChip(label: 'Keep planned'),
      ];
    case 'preWorkoutFuelGap':
      return [
        SuggestedReplyChip(
          label: 'Log a snack',
          actionKind: 'log_pre_workout_snack',
          actionPayload: p(),
        ),
        const SuggestedReplyChip(label: 'Why?'),
        SuggestedReplyChip(
          label: 'Start anyway',
          actionKind: 'start_workout_now',
          actionPayload: p(),
        ),
      ];
    case 'equipmentMismatch':
      return [
        SuggestedReplyChip(
          label: 'Bodyweight version',
          actionKind: 'swap_to_bodyweight_variant',
          actionPayload: p(),
        ),
        const SuggestedReplyChip(label: 'Why?'),
        const SuggestedReplyChip(label: 'Keep planned'),
      ];
    case 'cycleAdjusted':
      return [
        const SuggestedReplyChip(label: 'How should I train this phase?'),
        const SuggestedReplyChip(label: 'Why?'),
        const SuggestedReplyChip(label: 'Keep planned'),
      ];
    case 'morning_brief':
      return [
        SuggestedReplyChip(
          label: 'Log water',
          actionKind: 'log_water_now',
          actionPayload: p(),
        ),
        SuggestedReplyChip(
          label: 'Log breakfast',
          actionKind: 'log_breakfast',
          actionPayload: p(),
        ),
        const SuggestedReplyChip(label: "What's next?"),
      ];
    case 'evening_recap':
      return [
        SuggestedReplyChip(
          label: 'Plan tomorrow',
          actionKind: 'plan_tomorrow_meals',
          actionPayload: p(),
        ),
        SuggestedReplyChip(
          label: 'Wind down',
          actionKind: 'start_wind_down',
          actionPayload: p(),
        ),
        const SuggestedReplyChip(label: 'Recap details'),
      ];
    default:
      return const [
        SuggestedReplyChip(label: 'Why?'),
        SuggestedReplyChip(label: "What's next?"),
        SuggestedReplyChip(label: 'Quick check'),
      ];
  }
}

/// Horizontal chip strip. Designed to sit directly under a coach bubble
/// inside the chat list, NOT inside the input bar.
class SuggestedReplyChips extends StatelessWidget {
  final List<SuggestedReplyChip> chips;

  /// Fired when a chip without an [actionKind] / [route] is tapped. Caller
  /// should send the label as a user turn.
  final void Function(String label) onMessageTap;

  /// Fired when a chip with [actionKind] is tapped. Caller dispatches the
  /// action through the existing chat-notifier `_processActionData` switch.
  final void Function(String kind, Map<String, dynamic> payload) onActionTap;

  /// Fired when a chip carries a literal [route] (used for plain deep links).
  final void Function(String route) onRouteTap;

  const SuggestedReplyChips({
    super.key,
    required this.chips,
    required this.onMessageTap,
    required this.onActionTap,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(46, 6, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final chip in chips)
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                if (chip.route != null && chip.route!.isNotEmpty) {
                  onRouteTap(chip.route!);
                  return;
                }
                if (chip.actionKind != null) {
                  onActionTap(
                    chip.actionKind!,
                    chip.actionPayload ?? const {},
                  );
                  return;
                }
                onMessageTap(chip.label);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: c.accent.withValues(alpha: 0.30),
                  ),
                ),
                child: Text(
                  chip.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
