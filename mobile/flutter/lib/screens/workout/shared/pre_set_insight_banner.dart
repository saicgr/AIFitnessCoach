// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// 28 pt amber-accent banner that renders above the focal-card stepper. Shows
// a single AI insight ("averaged 9 reps last session — below range, try
// lighter") produced by `pre_set_insight_engine.dart`. Dismissible per set;
// collapses to zero height when the engine produces nothing.
//
// Per-set dismiss memory is SESSION-SCOPED and held in-memory (the plan
// explicitly calls out not persisting across workouts). Keyed on
// (exerciseId, setIndex) so dismissing set 3 doesn't mute set 4.
//
// TODO(easy/simple/advanced authors): `pre_set_insight_engine.dart` currently
// exposes insights keyed only by exerciseId (its `ExerciseInsightInput`
// doesn't carry a setIndex). The plan asks for a per-set getter; the
// enclosing screen already owns the exercise-level insight, so for now this
// banner accepts a pre-computed `insight` string and uses (exerciseId,
// setIndex) for dismiss tracking only. When the engine grows a real
// per-set API, swap the `insight` prop for an `ExerciseInsightInput` and
// compute internally. Do NOT modify the engine from this file (other agents
// own it).

import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/services/pre_set_insight_engine.dart' show InsightTone;
import '../../../core/theme/accent_color_provider.dart';

// Re-export the engine's `InsightTone` so existing callers that import only
// this file (e.g. the Simple focal card) keep compiling without a second
// import. The engine is the source of truth — the copy pools switch on it.
export '../../../core/services/pre_set_insight_engine.dart' show InsightTone;

/// Session-scoped in-memory dismissal set. Key format: `exerciseId#index`.
/// Intentionally a plain top-level Set so the state outlives widget rebuilds
/// but resets on process restart, matching the plan's "dismissed per-session"
/// rule. Not thread-safe, but Flutter UI is single-threaded.
final Set<String> _dismissed = <String>{};

/// Reset dismiss memory — called by the enclosing screen when the user
/// starts a fresh workout. Exposed so tests can reset state too.
void clearInsightDismissals() => _dismissed.clear();

String _key(String exerciseId, int setIndex) => '$exerciseId#$setIndex';

/// Whether this (exerciseId, setIndex) has been dismissed in this session.
bool isInsightDismissed(String exerciseId, int setIndex) =>
    _dismissed.contains(_key(exerciseId, setIndex));

class PreSetInsightBanner extends StatefulWidget {
  final String exerciseId;
  final int setIndex;

  /// Engine-computed copy. Pass `null` to render nothing (the caller already
  /// called `PreSetInsightEngine.computeCopy(input)`).
  final String? insight;

  /// Copy density — see `InsightTone`.
  final InsightTone tone;

  /// Optional label override. Defaults to "Tip" / "Coach" / "Data" based on
  /// tone. Useful for A/B variations in future.
  final String? leadingLabel;

  const PreSetInsightBanner({
    super.key,
    required this.exerciseId,
    required this.setIndex,
    required this.insight,
    this.tone = InsightTone.simple,
    this.leadingLabel,
  });

  @override
  State<PreSetInsightBanner> createState() => _PreSetInsightBannerState();
}

class _PreSetInsightBannerState extends State<PreSetInsightBanner> {
  late bool _dismissed;

  @override
  void initState() {
    super.initState();
    _dismissed = isInsightDismissed(widget.exerciseId, widget.setIndex);
  }

  @override
  void didUpdateWidget(covariant PreSetInsightBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the caller swaps to a new (exerciseId, setIndex) — for instance
    // because the user logged a set and the focal card advanced — re-check
    // the session dismissal set so the banner can reappear fresh.
    if (oldWidget.exerciseId != widget.exerciseId ||
        oldWidget.setIndex != widget.setIndex) {
      _dismissed = isInsightDismissed(widget.exerciseId, widget.setIndex);
    }
  }

  void _dismiss() {
    HapticService.instance.tick();
    _dismissed = true;
    _InsightMemory.add(widget.exerciseId, widget.setIndex);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.insight;
    final hidden = copy == null || copy.isEmpty || _dismissed;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: hidden
          ? const SizedBox(height: 0, width: double.infinity)
          : _BannerBody(
              copy: copy,
              tone: widget.tone,
              leadingLabel: widget.leadingLabel,
              onDismiss: _dismiss,
            ),
    );
  }
}

/// Internal helper so `_dismiss()` doesn't need access to the private Set.
class _InsightMemory {
  @visibleForTesting
  static void add(String exerciseId, int setIndex) {
    _dismissed.add(_key(exerciseId, setIndex));
  }
}

class _BannerBody extends StatelessWidget {
  final String copy;
  final InsightTone tone;
  final String? leadingLabel;
  final VoidCallback onDismiss;

  const _BannerBody({
    required this.copy,
    required this.tone,
    required this.leadingLabel,
    required this.onDismiss,
  });

  String get _defaultLabel {
    switch (tone) {
      case InsightTone.easy:
        return 'Coach';
      case InsightTone.simple:
        return 'Tip';
      case InsightTone.advanced:
        return 'Data';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurface = isDark ? Colors.white : Colors.black;
    final label = leadingLabel ?? _defaultLabel;

    final fontSize = tone == InsightTone.advanced ? 12.0 : 13.0;
    final weight =
        tone == InsightTone.easy ? FontWeight.w500 : FontWeight.w600;

    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('✨', style: TextStyle(fontSize: fontSize + 1)),
          const SizedBox(width: 6),
          Text(
            '$label · ',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          Expanded(
            child: Text(
              copy,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: weight,
                color: onSurface.withValues(alpha: 0.86),
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _DismissButton(onTap: onDismiss, accent: accent),
        ],
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color accent;

  const _DismissButton({required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Dismiss insight',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          child: Icon(Icons.close_rounded, size: 16, color: accent),
        ),
      ),
    );
  }
}
