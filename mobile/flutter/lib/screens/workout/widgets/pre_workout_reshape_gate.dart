// Pre-workout reshape GATE (Dr-Yaad audit #1) — the advise→act loop.
//
// When the user starts a workout we ask a 2-step check-in (Sleep + Readiness
// 0–10 gauges → "anything to flag?": sore/painful body part, minutes
// available), POST it to `/workouts/{id}/reshape-for-readiness`, and — if the
// engine reshaped the session — show the diff with an Accept gate. On Accept we
// hand the reshaped workout to the live session via [activeWorkoutLiveProvider]
// (the same channel mid-workout swaps already use), so the user trains the
// adjusted plan. Skipping leaves the original session untouched.
//
// Gated once per workout per local day so re-entering doesn't re-prompt. This
// is distinct from the older PreWorkoutCheckin mood-logging sheet — that logs
// subjective feedback; this RESHAPES the session.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/active_workout_phase_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../providers/active_workout_live_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';

/// Keys ("$workoutId|$yyyymmdd") for which the reshape gate already ran today.
final preWorkoutReshapeDoneProvider =
    StateProvider<Set<String>>((ref) => <String>{});

/// Common flaggable regions → backend body-part tokens.
const _bodyParts = <String, String>{
  'Shoulder': 'shoulder',
  'Knee': 'knee',
  'Lower back': 'lower_back',
  'Elbow': 'elbow',
  'Wrist': 'wrist',
  'Hip': 'hip',
  'Neck': 'neck',
  'Ankle': 'ankle',
};

String _dayKey(String? workoutId) {
  final now = DateTime.now();
  final d =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  return '${workoutId ?? 'w'}|$d';
}

/// SharedPreferences slot mirroring [preWorkoutReshapeDoneProvider].
///
/// The provider alone is RAM-only, so killing/relaunching the app re-armed the
/// gate and the user got the same check-in again for the same workout on the
/// same day — one more screen between them and their first set. Persisting the
/// day-key makes "once per workout per day" actually true.
const String _kReshapeDonePrefsKey = 'pre_workout_reshape_done_keys';

/// Today's suffix, used to prune stale keys so the slot can't grow forever.
String _todaySuffix() {
  final now = DateTime.now();
  return '|${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
}

Future<Set<String>> _loadDoneKeys() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_kReshapeDonePrefsKey) ?? const [];
    // Only today's keys matter; anything older is dropped on read.
    return stored.where((k) => k.endsWith(_todaySuffix())).toSet();
  } catch (e) {
    debugPrint('⚠️ [ReshapeGate] done-key load failed: $e');
    return <String>{};
  }
}

Future<void> _persistDoneKeys(Set<String> keys) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kReshapeDonePrefsKey,
      keys.where((k) => k.endsWith(_todaySuffix())).toList(),
    );
  } catch (e) {
    debugPrint('⚠️ [ReshapeGate] done-key persist failed: $e');
  }
}

/// Show the check-in once before the session starts and apply any reshape.
/// Best-effort: any failure silently proceeds with the original workout.
Future<void> maybeRunPreWorkoutReshape(
  BuildContext context,
  WidgetRef ref,
  Workout workout,
) async {
  final id = workout.id;
  if (id == null || id.isEmpty) return;
  final key = _dayKey(id);
  final done = ref.read(preWorkoutReshapeDoneProvider);
  if (done.contains(key)) return;
  // Disk mirror: survives an app relaunch, so the gate is genuinely once per
  // workout per day rather than once per process.
  final persisted = await _loadDoneKeys();
  if (persisted.contains(key)) {
    ref.read(preWorkoutReshapeDoneProvider.notifier).state = {...done, key};
    return;
  }
  if (!context.mounted) return;
  // Mark done up-front so a rebuild/re-entry can't double-prompt. Persist is
  // awaited (not fire-and-forget) so the disk mirror is guaranteed written
  // before the sheet can be dismissed — otherwise a kill/relaunch in the
  // gap between showing the sheet and the write landing re-armed the gate
  // and the check-in showed a second time for the same workout/day on resume.
  final nextDone = {...done, key};
  ref.read(preWorkoutReshapeDoneProvider.notifier).state = nextDone;
  await _persistDoneKeys({...persisted, key});

  // Gate the tier tour for the whole modal flow (sheet → reshape call → diff
  // dialog) so its spotlight never fires on top of this sheet, anchored to
  // widgets underneath it. Capture the controller up-front: it outlives the
  // calling widget, so the `finally` reset is safe even if the screen is
  // popped mid-sheet (a stale true would block tours on the NEXT workout).
  final tourGate = ref.read(preWorkoutModalDepthProvider.notifier);
  tourGate.state++;
  final clockGate = ref.read(preWorkoutClockGateProvider.notifier);
  clockGate.state = true;
  try {
    final input = await showGlassSheet<_CheckInInput>(
      context: context,
      builder: (_) => const _ReshapeCheckInSheet(),
    );
    // Sheet is dismissed either way (Start or Skip) — the clock should run
    // from here, regardless of the reshape network call/diff dialog below.
    clockGate.state = false;
    if (input == null || !context.mounted) return; // dismissed → no change

    final _ReshapeResult result;
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post(
        '/workouts/$id/reshape-for-readiness',
        data: input.toJson(apply: false),
      );
      result =
          _ReshapeResult.fromJson(Map<String, dynamic>.from(resp.data as Map));
    } catch (_) {
      return; // never block the start on a reshape error
    }

    if (!result.reshaped || result.reasons.isEmpty) return;
    if (!context.mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ReshapeDiffDialog(
        reasons: result.reasons,
        provenance: result.provenance,
      ),
    );
    if (accepted != true || !context.mounted) return;

    try {
      final client = ref.read(apiClientProvider);
      await client.post(
        '/workouts/$id/reshape-for-readiness',
        data: input.toJson(apply: true),
      );
    } catch (_) {
      // Persist failure is non-fatal — still apply locally for this session.
    }
    final reshaped = workout.copyWith(exercisesJson: result.reshapedExercises);
    ref.read(activeWorkoutLiveProvider.notifier).state = reshaped;
  } finally {
    tourGate.state--;
    clockGate.state = false;
  }
}

class _CheckInInput {
  final int sleep; // 0–10
  final int readiness; // 0–10
  final int? availableMinutes;
  final String? painPart; // backend token
  final int? painLevel; // 0–10

  const _CheckInInput({
    required this.sleep,
    required this.readiness,
    this.availableMinutes,
    this.painPart,
    this.painLevel,
  });

  Map<String, dynamic> toJson({required bool apply}) {
    final now = DateTime.now();
    final localDate = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return {
      'sleep_score': sleep,
      'readiness_score': readiness,
      if (availableMinutes != null) 'available_minutes': availableMinutes,
      if (painPart != null) 'pain_part': painPart,
      if (painLevel != null) 'pain_level': painLevel,
      'local_date': localDate,
      'apply': apply,
    };
  }
}

class _ReshapeResult {
  final bool reshaped;
  final List<String> reasons;
  final List<Map<String, dynamic>> reshapedExercises;
  final String provenance;

  const _ReshapeResult({
    required this.reshaped,
    required this.reasons,
    required this.reshapedExercises,
    required this.provenance,
  });

  factory _ReshapeResult.fromJson(Map<String, dynamic> json) => _ReshapeResult(
        reshaped: json['reshaped'] == true,
        reasons: (json['reasons'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        reshapedExercises:
            (json['reshaped_exercises'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
        provenance: (json['provenance'] as String?) ?? '',
      );
}

// ===========================================================================
// Check-in sheet
// ===========================================================================

class _ReshapeCheckInSheet extends StatefulWidget {
  const _ReshapeCheckInSheet();

  @override
  State<_ReshapeCheckInSheet> createState() => _ReshapeCheckInSheetState();
}

class _ReshapeCheckInSheetState extends State<_ReshapeCheckInSheet> {
  double _sleep = 7;
  double _readiness = 7;
  int? _minutes;
  String? _painPart;
  double _painLevel = 3;

  static const _minuteOptions = [20, 30, 45, 60];

  /// Everything the user might want to tell us lives on ONE page now.
  /// Previously this was a 2-step wizard (gauges → "anything to flag?"), which
  /// put TWO sequential full-width gates between "Start workout" and the first
  /// set. Same fields, same payload, one screen — and the optional half is
  /// collapsed behind a disclosure so the default path is: glance, tap Start.
  bool _flagsExpanded = false;

  void _submit() {
    HapticFeedback.selectionClick();
    Navigator.pop(
      context,
      _CheckInInput(
        sleep: _sleep.round(),
        readiness: _readiness.round(),
        availableMinutes: _minutes,
        painPart: _painPart,
        painLevel: _painPart != null ? _painLevel.round() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Frosted glass surface — GlassSheet supplies the BackdropFilter blur,
    // translucent background, rounded top, border, the standard drag handle,
    // and keyboard/home-indicator inset handling. We only own the content.
    return GlassSheet(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick check-in',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: text),
          ),
          const SizedBox(height: 4),
          Text(
            "I'll tune today's session to how you actually feel. "
            'Skip if you just want to train.',
            style: TextStyle(fontSize: 13, color: muted),
          ),
          const SizedBox(height: 18),
          // Scrolls internally so the two gauges + the expanded flags never
          // overflow an SE-class screen (and the action row stays pinned).
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._buildGauges(text, muted),
                  const SizedBox(height: 6),
                  // Optional half: time budget + sore/painful area. Collapsed
                  // by default — it used to be a mandatory second page.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _flagsExpanded = !_flagsExpanded);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            'Sore, short on time?',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: text),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _flagsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: muted,
                          ),
                          const Spacer(),
                          if (!_flagsExpanded &&
                              (_minutes != null || _painPart != null))
                            Text(
                              [
                                if (_minutes != null) '$_minutes min',
                                if (_painPart != null)
                                  _bodyParts.entries
                                      .firstWhere(
                                          (e) => e.value == _painPart)
                                      .key,
                              ].join(' · '),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.accentColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_flagsExpanded) ..._buildFlags(text, muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Skip is a first-class, visible control — the sheet used to be
              // dismissible only by swiping it away, which reads as a gate.
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context); // null → no check-in, no reshape
                },
                style: TextButton.styleFrom(foregroundColor: muted),
                child: const Text('Skip'),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submit,
                child: const Text('Start workout'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGauges(Color text, Color muted) => [
        _gauge('Sleep', _sleep, (v) => setState(() => _sleep = v), text),
        const SizedBox(height: 18),
        _gauge('Readiness', _readiness, (v) => setState(() => _readiness = v),
            text),
      ];

  Widget _gauge(
      String label, double value, ValueChanged<double> onChanged, Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: text)),
            Text('${value.round()}/10',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.accentColor)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: context.accentColor,
          label: '${value.round()}',
          onChanged: onChanged,
        ),
      ],
    );
  }

  List<Widget> _buildFlags(Color text, Color muted) => [
        Text('Time available',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: text)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in _minuteOptions)
              _chip('$m min', _minutes == m,
                  () => setState(() => _minutes = _minutes == m ? null : m)),
          ],
        ),
        const SizedBox(height: 18),
        Text('Sore or painful area?',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: text)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _bodyParts.entries)
              _chip(entry.key, _painPart == entry.value, () {
                setState(() => _painPart =
                    _painPart == entry.value ? null : entry.value);
              }),
          ],
        ),
        if (_painPart != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pain level',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: text)),
              Text('${_painLevel.round()}/10',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.accentColor)),
            ],
          ),
          Slider(
            value: _painLevel,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: context.accentColor,
            onChanged: (v) => setState(() => _painLevel = v),
          ),
          Text(
            _painLevel.round() >= 4
                ? "I'll swap the moves that load it."
                : "I'll keep an eye on it (no swap under 4/10).",
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ];

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? context.accentColor.withOpacity(0.16)
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? context.accentColor
                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? context.accentColor
                : (isDark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Reshape diff dialog (the Accept gate)
// ===========================================================================

class _ReshapeDiffDialog extends StatelessWidget {
  final List<String> reasons;
  final String provenance;
  const _ReshapeDiffDialog({required this.reasons, this.provenance = ''});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_fix_high_rounded, size: 20, color: context.accentColor),
          SizedBox(width: 8),
          Expanded(child: Text('Reshaped for today')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 5, right: 8),
                    child: Icon(Icons.check_circle,
                        size: 14, color: context.accentColor),
                  ),
                  Expanded(
                    child: Text(r, style: const TextStyle(fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          // Provenance / trust footer (Dr-Yaad audit #12) — the engine drafts;
          // you decide. Reinforces "nothing changes until you accept".
          if (provenance.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1, right: 6),
                  child: Icon(Icons.verified_outlined,
                      size: 13, color: ThemeColors.of(context).textMuted),
                ),
                Expanded(
                  child: Text(
                    provenance,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: ThemeColors.of(context).textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Reject'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.accentColor),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}
