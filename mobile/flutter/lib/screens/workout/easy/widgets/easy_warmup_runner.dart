// Easy tier — guided warm-up runner.
//
// Shown BEFORE the working sets when the workout has warm-up moves (Easy used
// to skip warm-up entirely). Kept deliberately SEPARATE from the logged
// exercise list: warm-up moves are never written to the session/sets, so they
// can't drift the working-set indices or inflate volume / PR stats — they're
// excluded from everything by construction.
//
// Flow: an intro card (N moves · ~M min · Start / Skip) → a sequence of timed
// moves (one big countdown each, reusing TimedExerciseTimer's play/pause) with
// per-move "Skip" and a global "Skip warm-up". `onDone` fires when the user
// finishes or skips, handing control back to the working sets.

import 'package:flutter/material.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../widgets/exercise_image.dart';
import '../../widgets/timed_exercise_timer.dart';

class EasyWarmupRunner extends StatefulWidget {
  /// Raw warm-up item maps (name / duration_seconds / exercise_id …) as
  /// returned by `WorkoutRepository.fetchWarmupAndStretches`.
  final List<Map<String, dynamic>> warmup;

  /// Called once the warm-up is finished OR skipped — proceed to working sets.
  final VoidCallback onDone;

  const EasyWarmupRunner({super.key, required this.warmup, required this.onDone});

  @override
  State<EasyWarmupRunner> createState() => _EasyWarmupRunnerState();
}

class _EasyWarmupRunnerState extends State<EasyWarmupRunner> {
  bool _started = false;
  int _index = 0;

  int _durationOf(Map<String, dynamic> m) {
    final v = m['duration_seconds'] ?? m['durationSeconds'];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 30;
    return 30;
  }

  String _nameOf(Map<String, dynamic> m) => m['name']?.toString() ?? 'Warm-up';

  void _next() {
    if (_index + 1 >= widget.warmup.length) {
      widget.onDone();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;

    final totalSecs =
        widget.warmup.fold<int>(0, (s, m) => s + _durationOf(m));
    final mins = (totalSecs / 60).ceil();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: !_started
            ? _intro(tc, mins)
            : _runMove(tc, widget.warmup[_index]),
      ),
    );
  }

  // ── Intro card: N moves · ~M min · Start / Skip ──────────────────────────
  Widget _intro(ThemeColors tc, int mins) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('WARM-UP',
                style: ZType.lbl(12, color: tc.accent, letterSpacing: 2.5)),
          ),
          const SizedBox(height: 4),
          Text('${widget.warmup.length} moves · ~$mins min',
              style: ZType.disp(26, color: tc.textPrimary)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: widget.warmup.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = widget.warmup[i];
                return Row(
                  children: [
                    ExerciseImage(
                      exerciseName: _nameOf(m),
                      exerciseId: m['exercise_id']?.toString(),
                      width: 40,
                      height: 40,
                      borderRadius: 9,
                      fit: BoxFit.cover,
                      iconColor: tc.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_nameOf(m),
                          style: ZType.sans(15,
                              color: tc.textPrimary, weight: FontWeight.w600)),
                    ),
                    Text('${_durationOf(m)}s',
                        style: ZType.data(13, color: tc.textMuted)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                HapticService.instance.tap();
                setState(() => _started = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tc.accent,
                foregroundColor: tc.accentContrast,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text('START WARM-UP',
                  style: ZType.lbl(16,
                      color: tc.accentContrast,
                      weight: FontWeight.w800,
                      letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                HapticService.instance.tap();
                widget.onDone();
              },
              child: Text('SKIP WARM-UP →',
                  style: ZType.lbl(13, color: tc.textMuted, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Running a single timed move ──────────────────────────────────────────
  Widget _runMove(ThemeColors tc, Map<String, dynamic> m) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('WARM-UP · ${_index + 1} OF ${widget.warmup.length}',
                style: ZType.lbl(12, color: tc.accent, letterSpacing: 2)),
          ),
          const SizedBox(height: 8),
          Text(_nameOf(m).toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.disp(24, color: tc.textPrimary)),
          const Spacer(),
          // Reuse the timed countdown (with built-in play/pause). Advances to
          // the next move when the hold completes.
          TimedExerciseTimer(
            key: ValueKey('warmup_${_index}_${_nameOf(m)}'),
            durationSeconds: _durationOf(m),
            exerciseName: _nameOf(m),
            setNumber: _index + 1,
            totalSets: widget.warmup.length,
            autoStart: true,
            onComplete: () {
              HapticService.instance.success();
              _next();
            },
          ),
          const Spacer(),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                HapticService.instance.tap();
                _next();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: tc.textPrimary,
                side: BorderSide(color: tc.cardBorder),
                shape: const StadiumBorder(),
              ),
              child: Text(
                _index + 1 >= widget.warmup.length
                    ? 'DONE — START WORKOUT'
                    : 'NEXT MOVE →',
                style: ZType.lbl(14, color: tc.textPrimary, letterSpacing: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              HapticService.instance.tap();
              widget.onDone();
            },
            child: Text('SKIP WARM-UP →',
                style: ZType.lbl(12, color: tc.textMuted, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }
}
