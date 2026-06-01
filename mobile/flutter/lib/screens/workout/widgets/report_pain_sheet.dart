// Mid-workout pain reporter.
//
// Thin GlassSheet that lets the user flag pain on a specific exercise without
// leaving the active workout. On confirm it adds the exercise to the avoided
// list with a structured `pain:<severity>` reason and an optional auto-expiry
// (1 week / 2 weeks / no expiry). The avoidance provider already invalidates
// today + all-workouts caches so the next regeneration drops the exercise.
//
// Usage:
//   await ReportPainSheet.show(
//     context,
//     exerciseName: 'Bench Press',
//     exerciseId: ex.id,
//   );
// Returns true if the user confirmed (and the call succeeded), false on
// cancel or error.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/avoided_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Pain severity ↔ encoded reason. Kept in sync with the avoided-list
/// reason convention `pain:<severity>` consumed by analytics + future
/// pain-history surfacing.
enum _PainSeverity { mild, sharp, severe }

extension on _PainSeverity {
  String get label => switch (this) {
        _PainSeverity.mild => 'Mild',
        _PainSeverity.sharp => 'Sharp',
        _PainSeverity.severe => 'Severe',
      };

  String get blurb => switch (this) {
        _PainSeverity.mild => 'Slight discomfort',
        _PainSeverity.sharp => 'Sudden, pinpoint pain',
        _PainSeverity.severe => 'Stop the set immediately',
      };

  IconData get icon => switch (this) {
        _PainSeverity.mild => Icons.sentiment_dissatisfied_rounded,
        _PainSeverity.sharp => Icons.bolt_rounded,
        _PainSeverity.severe => Icons.warning_amber_rounded,
      };

  String get apiValue => switch (this) {
        _PainSeverity.mild => 'mild',
        _PainSeverity.sharp => 'sharp',
        _PainSeverity.severe => 'severe',
      };
}

class _Window {
  final String label;
  final Duration? duration; // null => permanent ("until I remove it")
  const _Window(this.label, this.duration);
}

const _windows = <_Window>[
  _Window('1 week', Duration(days: 7)),
  _Window('2 weeks', Duration(days: 14)),
  _Window('Until I remove it', null),
];

class ReportPainSheet extends ConsumerStatefulWidget {
  final String exerciseName;
  final String? exerciseId;
  // The exercise's primary muscle/body area. When present AND the pain is
  // sharp/severe (a real injury, not exercise-specific discomfort), we ALSO
  // file a provisional body-part injury into the phase-aware injury system so
  // the whole area is protected and enters the recovery lifecycle — not just
  // this one exercise avoided.
  final String? bodyPart;

  const ReportPainSheet({
    super.key,
    required this.exerciseName,
    this.exerciseId,
    this.bodyPart,
  });

  static Future<bool> show(
    BuildContext context, {
    required String exerciseName,
    String? exerciseId,
    String? bodyPart,
  }) async {
    final result = await showGlassSheet<bool>(
      context: context,
      builder: (_) => GlassSheet(
        child: ReportPainSheet(
          exerciseName: exerciseName,
          exerciseId: exerciseId,
          bodyPart: bodyPart,
        ),
      ),
    );
    return result == true;
  }

  @override
  ConsumerState<ReportPainSheet> createState() => _ReportPainSheetState();
}

class _ReportPainSheetState extends ConsumerState<ReportPainSheet> {
  _PainSeverity? _severity;
  int _windowIdx = 1; // default = 2 weeks
  bool _submitting = false;

  /// Map the pain sheet's severity (mild|sharp|severe) to an injury severity.
  /// Mild pain stays exercise-specific (no body-part injury filed).
  String? _injurySeverityFor(String painApiValue) {
    switch (painApiValue) {
      case 'sharp':
        return 'moderate';
      case 'severe':
        return 'severe';
      default:
        return null;
    }
  }

  Future<void> _confirm() async {
    final severity = _severity;
    if (severity == null || _submitting) return;
    setState(() => _submitting = true);
    HapticService.instance.tap();

    final ok = await ref.read(avoidedProvider.notifier).reportPain(
          widget.exerciseName,
          exerciseId: widget.exerciseId,
          severity: severity.apiValue,
          duration: _windows[_windowIdx].duration,
        );

    // F4 integration: for sharp/severe pain on a known body area, ALSO file a
    // provisional body-part injury so the phase-aware engine protects the whole
    // area + the recovery lifecycle (check-in, ease-in) kicks in. Mild pain
    // stays exercise-specific (avoid only). Best-effort — never blocks the flow.
    final injurySeverity = _injurySeverityFor(severity.apiValue);
    final part = widget.bodyPart?.trim();
    if (ok && injurySeverity != null && part != null && part.isNotEmpty) {
      try {
        await ref.read(apiClientProvider).injuryAction(
              action: 'report_pain',
              bodyPart: part,
              severity: injurySeverity,
            );
      } catch (_) {
        // Non-fatal: the exercise is already avoided; injury filing is a bonus.
      }
    }

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${widget.exerciseName} flagged for pain — we\'ll skip it ${_windows[_windowIdx].duration == null ? 'until you re-enable it' : 'for ${_windows[_windowIdx].label}'}.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsetsDirectional.only(bottom: 90, start: 16, end: 16),
        ),
      );
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).reportPainCouldNotSavePlease),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final fg = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 20,
        end: 20,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).reportPainPainOnThisExercise,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
          const SizedBox(height: 4),
          Text(widget.exerciseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14, color: fg.withValues(alpha: 0.62))),
          const SizedBox(height: 16),
          // 3 severity tiles
          Row(
            children: [
              for (final s in _PainSeverity.values) ...[
                Expanded(
                  child: _SeverityTile(
                    severity: s,
                    selected: _severity == s,
                    accent: accent,
                    fg: fg,
                    isDark: isDark,
                    onTap: () => setState(() => _severity = s),
                  ),
                ),
                if (s != _PainSeverity.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(AppLocalizations.of(context).reportPainSkipThisExercise,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.72))),
          const SizedBox(height: 8),
          // Duration segmented control
          Container(
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                for (var i = 0; i < _windows.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _windowIdx = i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 36,
                        decoration: BoxDecoration(
                          color: _windowIdx == i
                              ? accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _windows[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _windowIdx == i
                                ? (isDark ? Colors.black : Colors.white)
                                : fg.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _severity == null || _submitting ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? Colors.black : Colors.white,
                minimumSize: const Size.fromHeight(46),
                disabledBackgroundColor: fg.withValues(alpha: 0.14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(AppLocalizations.of(context).reportPainSkipAvoid,
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed:
                  _submitting ? null : () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context).buttonCancel,
                  style: TextStyle(color: fg.withValues(alpha: 0.6))),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityTile extends StatelessWidget {
  final _PainSeverity severity;
  final bool selected;
  final Color accent;
  final Color fg;
  final bool isDark;
  final VoidCallback onTap;

  const _SeverityTile({
    required this.severity,
    required this.selected,
    required this.accent,
    required this.fg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.instance.tap();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : fg.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent
                : fg.withValues(alpha: 0.08),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(severity.icon,
                size: 22, color: selected ? accent : fg.withValues(alpha: 0.7)),
            const SizedBox(height: 6),
            Text(severity.label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
            const SizedBox(height: 2),
            Text(severity.blurb,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: fg.withValues(alpha: 0.56))),
          ],
        ),
      ),
    );
  }
}
