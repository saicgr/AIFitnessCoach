/// Quick Adjust Sheet
///
/// Bottom sheet opened from the "Adjust" action chip on the active-workout
/// screen. Three sliders (soreness, energy, minutes-available) + a live
/// preview showing what will happen, + a single "Adapt workout" button.
///
/// Posts to `POST /api/v1/workouts/{workout_id}/quick-adjust` which returns
/// an updated exercises list. The caller is responsible for applying the
/// response to active-workout state (and showing an undo toast).
///
/// Design choices:
/// - Sliders (not chip groups) per feedback_increment_ui.md — compact,
///   non-scrollable, feels professional.
/// - Live preview recomputes locally as sliders move, so users see the
///   expected outcome before committing. Server runs the authoritative
///   decision tree on Submit — preview is a readable hint, not a contract.
/// - No silent fallback on network error (feedback_no_silent_fallbacks.md):
///   shows explicit error state with retry.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';

/// Response from POST /workouts/{id}/quick-adjust.
class QuickAdjustResult {
  /// "trim" | "ease" | "ease_and_trim" | "reschedule_suggested" | "none"
  final String action;
  final List<String> exercisesRemoved;
  final int setsDroppedPerExercise;
  final int estimatedMinutes;
  final String coachMessage;
  final List<Map<String, dynamic>>? updatedExercises;

  const QuickAdjustResult({
    required this.action,
    required this.exercisesRemoved,
    required this.setsDroppedPerExercise,
    required this.estimatedMinutes,
    required this.coachMessage,
    this.updatedExercises,
  });

  factory QuickAdjustResult.fromJson(Map<String, dynamic> json) {
    return QuickAdjustResult(
      action: json['action'] as String? ?? 'none',
      exercisesRemoved: ((json['exercises_removed'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      setsDroppedPerExercise: (json['sets_dropped_per_exercise'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 0,
      coachMessage: json['coach_message'] as String? ?? '',
      updatedExercises: (json['updated_exercises'] as List?)
          ?.cast<Map<String, dynamic>>(),
    );
  }

  bool get shouldReschedule => action == 'reschedule_suggested';
}

/// Opens the sheet and awaits the server response. Returns null if the
/// user closes without submitting.
Future<QuickAdjustResult?> showQuickAdjustSheet({
  required BuildContext context,
  required WidgetRef ref,
  required int workoutId,
  required List<int> remainingIndices,
  required int currentEstimatedMinutes,
}) {
  return showGlassSheet<QuickAdjustResult>(
    context: context,
    builder: (ctx) => GlassSheet(
      maxHeightFraction: 0.9,
      child: _QuickAdjustSheet(
        ref: ref,
        workoutId: workoutId,
        remainingIndices: remainingIndices,
        currentEstimatedMinutes: currentEstimatedMinutes,
      ),
    ),
  );
}

class _QuickAdjustSheet extends StatefulWidget {
  final WidgetRef ref;
  final int workoutId;
  final List<int> remainingIndices;
  final int currentEstimatedMinutes;

  const _QuickAdjustSheet({
    required this.ref,
    required this.workoutId,
    required this.remainingIndices,
    required this.currentEstimatedMinutes,
  });

  @override
  State<_QuickAdjustSheet> createState() => _QuickAdjustSheetState();
}

class _QuickAdjustSheetState extends State<_QuickAdjustSheet> {
  double _soreness = 3;
  double _energy = 5;
  late double _minutes;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default minutes slider = the current remaining time. Users drag DOWN
    // when pressed for time; the "no change" default minimizes surprise.
    _minutes = widget.currentEstimatedMinutes.toDouble().clamp(5, 120);
  }

  // ── Live preview (deterministic client-side mirror of server) ────────

  String _previewLine() {
    // Matches the server decision tree in quick_adjust.py so the preview
    // is honest. If we drift from the server, the preview is advisory only —
    // server is authoritative and returns the actual summary in coach_message.
    if (_energy <= 2 || _minutes <= 5) {
      return "We'll suggest rescheduling today's workout.";
    }
    final needsTrim = _minutes * 1.15 < widget.currentEstimatedMinutes;
    final needsEase = _soreness >= 5 && _energy <= 3;
    if (needsTrim && needsEase) {
      return "We'll trim accessories and ease intensity. ~${_minutes.round()} min.";
    }
    if (needsTrim) {
      return "We'll trim accessories to fit ~${_minutes.round()} min.";
    }
    if (needsEase) {
      return "We'll drop 1 set per remaining exercise.";
    }
    return 'No changes needed — you got this.';
  }

  // ── Submit ──────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final api = widget.ref.read(apiClientProvider);
      final response = await api.dio.post(
        '${ApiConstants.workouts}/${widget.workoutId}/quick-adjust',
        data: {
          'soreness': _soreness.round(),
          'energy': _energy.round(),
          'minutes_available': _minutes.round(),
          'exercise_indices_remaining': widget.remainingIndices,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 8),
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw StateError('Quick-adjust failed: HTTP ${response.statusCode}');
      }

      final result = QuickAdjustResult.fromJson(
        response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>,
      );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Could not adjust. Tap to retry.';
      });
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      // GlassSheet provides its own handle + translucent rounded surface,
      // so render only the content column here — no outer Container.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: TextStyle(
                color: fg,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust today\'s workout in place.',
              style: TextStyle(
                color: fg.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            _SliderRow(
              label: 'Soreness',
              leftLabel: 'None',
              rightLabel: 'Very sore',
              value: _soreness,
              min: 1,
              max: 7,
              divisions: 6,
              accent: accent,
              fg: fg,
              onChanged: (v) => setState(() => _soreness = v),
            ),
            const SizedBox(height: 16),
            _SliderRow(
              label: 'Energy',
              leftLabel: 'Drained',
              rightLabel: 'Peak',
              value: _energy,
              min: 1,
              max: 7,
              divisions: 6,
              accent: accent,
              fg: fg,
              onChanged: (v) => setState(() => _energy = v),
            ),
            const SizedBox(height: 16),
            _SliderRow(
              label: 'Time available',
              leftLabel: '5 min',
              rightLabel: '120 min',
              value: _minutes,
              min: 5,
              max: 120,
              divisions: 23, // 5-min steps
              accent: accent,
              fg: fg,
              valueLabel: '${_minutes.round()} min',
              onChanged: (v) => setState(() => _minutes = v),
            ),
            const SizedBox(height: 20),

            // Live preview strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _previewLine(),
                      style: TextStyle(
                        color: fg,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Adapt workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String leftLabel;
  final String rightLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color accent;
  final Color fg;
  final String? valueLabel;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.accent,
    required this.fg,
    required this.onChanged,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              valueLabel ?? value.round().toString(),
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            inactiveTrackColor: fg.withValues(alpha: 0.1),
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leftLabel,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                rightLabel,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
