import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

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

  /// Optional tooltip override.
  final String? semanticLabel;

  const AskCoachButton({
    super.key,
    required this.contextLabel,
    required this.statSnapshot,
    this.semanticLabel,
  });

  @override
  State<AskCoachButton> createState() => _AskCoachButtonState();
}

class _AskCoachButtonState extends State<AskCoachButton> {
  bool _pressed = false;

  void _onTap() {
    HapticService.selection();
    final encoded = Uri.encodeQueryComponent(widget.contextLabel);
    GoRouter.of(context).push(
      '/chat?source=pillar_stat&context=$encoded',
      extra: {
        'pillarStat': widget.statSnapshot,
        'contextLabel': widget.contextLabel,
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
