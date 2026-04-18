import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/mood.dart';
import '../../data/models/workout.dart';
import '../../widgets/breath_prompt_widget.dart';
import '../../widgets/grounding_prompt_widget.dart';

/// Pre-start screen that runs a breath or grounding prompt appropriate to
/// the mood-generated workout, then routes to the active workout screen.
///
/// When the mood has no prompt config, it auto-skips to the workout
/// immediately so the user never sees a blank screen.
class MoodWorkoutPreStartScreen extends ConsumerStatefulWidget {
  final Workout workout;

  const MoodWorkoutPreStartScreen({super.key, required this.workout});

  @override
  ConsumerState<MoodWorkoutPreStartScreen> createState() =>
      _MoodWorkoutPreStartScreenState();
}

class _MoodWorkoutPreStartScreenState
    extends ConsumerState<MoodWorkoutPreStartScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // If the workout doesn't have a breath/grounding prompt, skip immediately.
    final meta = widget.workout.generationMetadata ?? const {};
    final breath = meta['mood_breath_prompt'];
    if (breath == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go());
    }
  }

  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    // Replace the pre-start on the stack so Back from the workout goes to
    // the home/mood history, not back to this screen.
    context.pushReplacement(
      '/workout/${widget.workout.id}',
      extra: widget.workout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.workout.generationMetadata ?? const {};
    final moodStr = meta['mood'] as String? ?? 'good';
    final mood = Mood.fromString(moodStr);
    final accent = mood.color;

    final breath = meta['mood_breath_prompt'];

    // Anxious users get the grounding variant for variety; the breath
    // widget is the default for Angry / Stressed.
    if (mood == Mood.anxious && breath != null) {
      return GroundingPromptWidget(accentColor: accent, onDone: _go);
    }

    if (breath is Map) {
      final config = Map<String, dynamic>.from(breath);
      return BreathPromptWidget(
        config: config,
        accentColor: accent,
        onDone: _go,
      );
    }

    // Fallback — should never hit because initState routes away, but kept
    // defensively so a hot-reload edge case doesn't show a blank screen.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
