import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Valid `source` query-parameter values the chat screen and backend coach
/// agent recognise. Adding to this list MUST be paired with a matching `case`
/// branch in `coach_agent/nodes.py` source-bias `match` block (SLICE_COACH).
///
/// - `pillar_stat`        : tapped from a pillar stat tile (existing default).
/// - `cardio_detail`      : tapped from a cardio session detail screen.
/// - `training_load`      : tapped from the training-load card.
/// - `race_predictor`     : tapped from the race-predictor card.
/// - `refuel`             : tapped from the refuel / nutrition-after-cardio card.
/// - `vo2max`             : tapped from the VO2max card.
/// - `cardio_pr`          : tapped from a cardio PR celebration.
const Set<String> kValidAskCoachSources = {
  'pillar_stat',
  'cardio_detail',
  'training_load',
  'race_predictor',
  'refuel',
  'vo2max',
  'cardio_pr',
};

/// Toggle (always true) — kept as a named const so the assert in the
/// AskCoachButton constructor is removable in one place if a release
/// profile ever needs it. Asserts only run in debug Flutter builds, so
/// shipping with `true` here is safe in profile/release modes.
const bool _kSourceAssertions = true;

/// Small reusable "Ask Coach" affordance.
///
/// Renders the Material sparkle (`Icons.auto_awesome`) at 18pt in the
/// current accent colour, 0.6 opacity at rest and 1.0 when pressed. Tapping
/// pushes `/chat` with `?source=pillar_stat&context=<contextLabel>` so the
/// chat screen can surface a context-aware system prompt. [statSnapshot]
/// is forwarded via `extra` for any caller that wants to bias the prompt;
/// the chat screen's wiring of `extra` is a separate task.
class AskCoachButton extends StatefulWidget {
  /// Human-readable label describing what the user would be asking about —
  /// e.g. `"Train · today's completion"` or `"Nourish · protein hit %"`. URL
  /// encoded into the chat deep link so it survives navigation.
  final String contextLabel;

  /// Structured snapshot of the surrounding stats — forwarded as the
  /// `chat` route's `extra` map under the `pillarStat` key.
  final Map<String, dynamic> statSnapshot;

  /// The `source` query param the backend coach agent uses to bias its
  /// system prompt (see `coach_agent/nodes.py` source dispatch). Defaults
  /// to `'pillar_stat'` so existing pillar callers are unchanged. Must be a
  /// member of [kValidAskCoachSources]; an invalid value is silently
  /// downgraded to `pillar_stat` to avoid breaking the user flow.
  final String source;

  /// Optional tooltip override.
  final String? semanticLabel;

  AskCoachButton({
    super.key,
    required this.contextLabel,
    required this.statSnapshot,
    this.source = 'pillar_stat',
    this.semanticLabel,
  })  : assert(
          kValidAskCoachSources.contains(source) ||
              !_kSourceAssertions, // assertions only in dev to flag typos
          'AskCoachButton: unknown source "$source" — add it to kValidAskCoachSources AND the matching coach_agent/nodes.py case.',
        );

  @override
  State<AskCoachButton> createState() => _AskCoachButtonState();
}

class _AskCoachButtonState extends State<AskCoachButton> {
  bool _pressed = false;

  void _onTap() {
    HapticService.selection();
    final encoded = Uri.encodeQueryComponent(widget.contextLabel);
    // Downgrade silently to pillar_stat if a caller passed an unknown source
    // (defensive — debug builds already asserted).
    final src = kValidAskCoachSources.contains(widget.source)
        ? widget.source
        : 'pillar_stat';
    GoRouter.of(context).push(
      '/chat?source=$src&context=$encoded',
      extra: {
        'pillarStat': widget.statSnapshot,
        'contextLabel': widget.contextLabel,
        'source': src,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    return Semantics(
      label: widget.semanticLabel ?? 'Ask coach about ${widget.contextLabel}',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: _pressed ? 1.0 : 0.6,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: _pressed ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: accent,
            ),
          ),
        ),
      ),
    );
  }
}
