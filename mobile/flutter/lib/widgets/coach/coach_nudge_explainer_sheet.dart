/// Glass-blur centered modal that explains a [ContextualNudge] to the user
/// when they tap the row's text area. The CTA pill on the row remains a
/// direct shortcut and never opens this modal.
///
/// Contents (in order):
///   * `×` close button (top-right)
///   * Large icon (the same emoji the row uses, sized up)
///   * Title (matches the row title)
///   * Long-form explainer — server-provided override if present, else the
///     deterministic local string keyed by [NudgeId].
///   * "Why this fired" line — short sentence describing the trigger.
///   * `[Got it]` (primary) + `[Dismiss]` (secondary). Got it closes only.
///     Dismiss snoozes the nudge for 4 hours via `nudgeSnoozeProvider`.
///   * Tap outside the card = same as Got it (close, no snooze).
///
/// Backdrop: `BackdropFilter` blur 16 + black opacity 0.3.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/models/contextual_nudge.dart';
import '../../data/providers/nudge_snooze_provider.dart';

/// Long-form per-nudge copy. The body is 2–3 sentences explaining the
/// "why" of the nudge; the trigger line is one short sentence describing
/// what made it fire.
class _NudgeExplainerCopy {
  final String body;
  final String trigger;
  const _NudgeExplainerCopy({required this.body, required this.trigger});
}

const Map<NudgeId, _NudgeExplainerCopy> _kNudgeExplainers = {
  NudgeId.hydration: _NudgeExplainerCopy(
    body:
        'Your body loses roughly a litre of water overnight through breath '
        'and sweat. Drinking 16 oz before coffee rehydrates faster than '
        'caffeine and tends to lift morning energy more than a second cup.',
    trigger: 'You have not logged water yet this morning.',
  ),
  NudgeId.breakfast: _NudgeExplainerCopy(
    body:
        'A protein-forward first meal blunts the mid-morning crash and '
        'sets the day up to hit your daily protein target without a '
        'rushed evening top-up.',
    trigger: 'Breakfast is not logged for today.',
  ),
  NudgeId.lunch: _NudgeExplainerCopy(
    body:
        'Lunch is the swing meal. Hit your protein here and dinner can be '
        'lighter and earlier, which also lines up better with sleep.',
    trigger: 'Lunch is not logged for today.',
  ),
  NudgeId.dinner: _NudgeExplainerCopy(
    body:
        'A balanced dinner with most of your remaining protein helps '
        'overnight muscle repair. Heavy carbs late tend to push sleep '
        'efficiency down.',
    trigger: 'Dinner is not logged for today.',
  ),
  NudgeId.workout: _NudgeExplainerCopy(
    body:
        "Today's workout is queued up. Starting earlier in the day "
        'preserves evening recovery and leaves a buffer if the session '
        'runs long.',
    trigger: 'Your scheduled workout has not started yet.',
  ),
  NudgeId.windDown: _NudgeExplainerCopy(
    body:
        'A short journal entry an hour before bed lowers cognitive load '
        'and improves sleep onset. It also gives the coach context for '
        "tomorrow's brief.",
    trigger: "Today's workout is done and you are inside the wind-down window.",
  ),
};

/// Show the explainer modal. Returns once the modal is closed.
Future<void> showCoachNudgeExplainer(
  BuildContext context, {
  required ContextualNudge nudge,
  required WidgetRef ref,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.30),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: _CoachNudgeExplainerCard(nudge: nudge, parentRef: ref),
        ),
      );
    },
  );
}

class _CoachNudgeExplainerCard extends StatelessWidget {
  final ContextualNudge nudge;
  final WidgetRef parentRef;
  const _CoachNudgeExplainerCard({
    required this.nudge,
    required this.parentRef,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final copy = _kNudgeExplainers[nudge.id] ??
        const _NudgeExplainerCopy(
          body: '',
          trigger: '',
        );
    final longBody = (nudge.explainerOverride != null &&
            nudge.explainerOverride!.trim().isNotEmpty)
        ? nudge.explainerOverride!.trim()
        : copy.body;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
                decoration: BoxDecoration(
                  color: c.elevated.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(nudge.icon,
                            style: const TextStyle(fontSize: 30)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: c.textMuted),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nudge.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (longBody.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        longBody,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                    if (copy.trigger.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Why this fired',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: c.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        copy.trigger,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: c.accentContrast,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Got it'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              parentRef
                                  .read(nudgeSnoozeProvider.notifier)
                                  .snooze(nudge.id);
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.textPrimary,
                              side: BorderSide(color: c.cardBorder),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Dismiss'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
