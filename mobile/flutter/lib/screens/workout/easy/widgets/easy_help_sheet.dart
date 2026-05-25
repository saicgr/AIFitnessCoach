// Easy tier — first-run help sheet.
//
// 3-slide tutorial (tap → next → next → done) per the approved plan:
//   1. Exercise header: "This is today's exercise. Tap ▶ Show video if
//      you need form help."
//   2. Steppers: "Adjust weight and reps with − and +. Long-press for
//      the keyboard."
//   3. Big ✓: "Tap when you finish a set. We'll handle the rest —
//      literally."
//
// Accessible from the chat sheet's "?" affordance. Bottom row:
//   [ Skip to next exercise ]   [ Switch to Simple ]
//
// Seen-state persisted via SharedPreferences key `tour_seen_easy`.
// Parent screen is responsible for firing `showIfNeverSeen()` once on
// first load; the helper below encapsulates the gate so the screen
// doesn't have to know about SharedPreferences internals.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/workout_ui_mode_provider.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../../../l10n/generated/app_localizations.dart';

const String _tourSeenKey = 'tour_seen_easy';

class EasyHelpSheet extends ConsumerStatefulWidget {
  final VoidCallback onSkipToNext;

  const EasyHelpSheet({super.key, required this.onSkipToNext});

  /// One-time first-run presentation. No-op if the user has already seen
  /// the Easy tour. Safe to call every time the Easy screen mounts.
  static Future<void> showIfNeverSeen(
    BuildContext context, {
    required VoidCallback onSkipToNext,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_tourSeenKey) == true) return;
    if (!context.mounted) return;

    await showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        showHandle: false, // sheet renders its own custom handle below
        child: EasyHelpSheet(onSkipToNext: onSkipToNext),
      ),
    );

    await prefs.setBool(_tourSeenKey, true);
  }

  @override
  ConsumerState<EasyHelpSheet> createState() => _EasyHelpSheetState();
}

class _EasyHelpSheetState extends ConsumerState<EasyHelpSheet> {
  int _step = 0;

  static List<_Slide> _buildSlides(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      _Slide(
        icon: Icons.fitness_center_rounded,
        title: l.easyHelpTodaysExercise,
        body: l.easyHelpTodaysExerciseBody,
      ),
      _Slide(
        icon: Icons.add_circle_outline_rounded,
        title: l.easyHelpWeightAndReps,
        body: l.easyHelpWeightAndRepsBody,
      ),
      _Slide(
        icon: Icons.check_circle_outline,
        title: l.easyHelpLogASet,
        body: l.easyHelpLogASetBody,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final fg = isDark ? Colors.white : Colors.black;
    final l = AppLocalizations.of(context)!;
    final slides = _buildSlides(context);
    final slide = slides[_step];
    final isLast = _step == slides.length - 1;

    // Outer glass surface is provided by `GlassSheet` (showGlassSheet wraps
    // us). Here we just lay out the slide content; bg/borderRadius come from
    // the GlassSheet so the coachmark matches every other glass sheet in
    // the app (was an opaque white card before — see issue #1).
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(slide.icon, size: 22, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(slide.title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: fg)),
              ),
              Text(
                '${_step + 1} / ${slides.length}',
                style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.48)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(slide.body,
              style: TextStyle(
                  fontSize: 15, height: 1.4, color: fg.withValues(alpha: 0.82))),
          const SizedBox(height: 22),
          // Primary action first (full width), then a muted secondary below.
          // "Skip to next exercise" doesn't fit in a half-width button without
          // wrapping, which reads as a layout bug.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Haptic fires in parallel; advancing slides doesn't
                // need to await it (keeps context-sync analyzer happy).
                HapticService.instance.tap();
                if (isLast) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _step++);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? Colors.black : Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(isLast ? l.exerciseDetailGotIt : l.commonNext,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSkipToNext();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: BorderSide(color: fg.withValues(alpha: 0.14)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l.easyHelpSkipToNextExercise,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg.withValues(alpha: 0.78))),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref
                    .read(workoutUiModeProvider.notifier)
                    .setMode(WorkoutUiMode.advanced);
              },
              child: Text(
                l.easyHelpSwitchToAdvanced,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide({required this.icon, required this.title, required this.body});
}
