/// Easy-tier active workout screen — widget shell.
///
/// Ultra-minimal: one set at a time via big ± steppers and a big ✓ button.
/// Beginners' cognitive budget is ~5 concepts — we ship exactly that.
///
/// Layout (hard no-scroll, fixed heights):
///   Column
///     ├─ EasyTopBar                (48 pt)
///     ├─ EasyExerciseHeader        (280 pt / 220 pt compact)
///     ├─ EasyCompletedDots         (36 pt)
///     ├─ PreSetInsightBanner       (28 pt, 0 when silent)
///     ├─ Expanded(focal steppers + ✓)
///     └─ EasyUpNextChip            (44 pt)
///   + Positioned EasyChatPill      (56 pt, bottom-right)
///
/// Rest after a logged set is pushed as a full-screen `EasyRestOverlay`
/// (PageRoute). When the countdown hits 0 the route pops and we advance
/// to the next set or exercise.
///
/// All business logic lives in `EasyActiveWorkoutScreenState`
/// (see easy_active_workout_state.dart). Posts each set via
/// `WorkoutRepository.logSetPerformance` with `loggingMode: 'easy'`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/workout.dart';
import 'easy_active_workout_state.dart';

class EasyActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Workout workout;
  final String? challengeId;
  final Map<String, dynamic>? challengeData;

  const EasyActiveWorkoutScreen({
    super.key,
    required this.workout,
    this.challengeId,
    this.challengeData,
  });

  @override
  ConsumerState<EasyActiveWorkoutScreen> createState() =>
      EasyActiveWorkoutScreenState();
}
