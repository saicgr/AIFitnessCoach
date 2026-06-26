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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/services/api_client.dart';
import '../providers/active_workout_live_provider.dart';

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
  // Mark done up-front so a rebuild/re-entry can't double-prompt.
  ref.read(preWorkoutReshapeDoneProvider.notifier).state = {...done, key};

  final input = await showModalBottomSheet<_CheckInInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ReshapeCheckInSheet(),
  );
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

  Map<String, dynamic> toJson({required bool apply}) => {
        'sleep_score': sleep,
        'readiness_score': readiness,
        if (availableMinutes != null) 'available_minutes': availableMinutes,
        if (painPart != null) 'pain_part': painPart,
        if (painLevel != null) 'pain_level': painLevel,
        'apply': apply,
      };
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
  int _step = 0;
  double _sleep = 7;
  double _readiness = 7;
  int? _minutes;
  String? _painPart;
  double _painLevel = 3;

  static const _minuteOptions = [20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : AppColorsLight.surface;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: muted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _step == 0 ? 'Quick check-in' : 'Anything to flag?',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: text),
          ),
          const SizedBox(height: 4),
          Text(
            _step == 0
                ? "I'll tune today's session to how you actually feel."
                : 'Tap a sore/painful area or set your time — or just continue.',
            style: TextStyle(fontSize: 13, color: muted),
          ),
          const SizedBox(height: 18),
          if (_step == 0)
            ..._buildGauges(text, muted)
          else
            ..._buildFlags(text, muted),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_step == 1)
                TextButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Back'),
                ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (_step == 0) {
                    setState(() => _step = 1);
                  } else {
                    Navigator.pop(
                      context,
                      _CheckInInput(
                        sleep: _sleep.round(),
                        readiness: _readiness.round(),
                        availableMinutes: _minutes,
                        painPart: _painPart,
                        painLevel:
                            _painPart != null ? _painLevel.round() : null,
                      ),
                    );
                  }
                },
                child: Text(_step == 0 ? 'Next' : 'Start workout'),
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
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cyan)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: AppColors.cyan,
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
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyan)),
            ],
          ),
          Slider(
            value: _painLevel,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: AppColors.cyan,
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
              ? AppColors.cyan.withOpacity(0.16)
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.cyan
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
                ? AppColors.cyan
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
        children: const [
          Icon(Icons.auto_fix_high_rounded, size: 20, color: AppColors.cyan),
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
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 8),
                    child: Icon(Icons.check_circle,
                        size: 14, color: AppColors.cyan),
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
                const Padding(
                  padding: EdgeInsets.only(top: 1, right: 6),
                  child: Icon(Icons.verified_outlined,
                      size: 13, color: AppColors.textMuted),
                ),
                Expanded(
                  child: Text(
                    provenance,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
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
          style: FilledButton.styleFrom(backgroundColor: AppColors.cyan),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}
