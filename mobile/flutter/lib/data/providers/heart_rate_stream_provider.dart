import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/health_service.dart';

/// Live heart-rate stream during an active workout. Polls HealthKit /
/// Health Connect every 5s — wearables (Amazfit Helios, Apple Watch,
/// Pixel Watch) write samples that surface here within ~5s of the beat.
///
/// Watching this provider in the active-workout header gives users the
/// "live HR while training" experience and feeds samples into the
/// per-workout HR buffer used by the post-workout graph.
final heartRateStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final service = ref.watch(healthServiceProvider);
  return service.streamLiveHeartRate();
});

/// In-memory buffer of (timestamp, bpm) samples for the active workout.
/// Cleared at workout start; consumed by the post-workout HR graph.
/// Kept here (not in Drift) intentionally — short-lived per-session
/// data that doesn't need to survive crashes.
class HeartRateBuffer extends StateNotifier<List<HeartRateSample>> {
  HeartRateBuffer() : super(const []);

  void clear() => state = const [];

  void add(int bpm) {
    state = [...state, HeartRateSample(DateTime.now(), bpm)];
  }
}

class HeartRateSample {
  final DateTime t;
  final int bpm;
  const HeartRateSample(this.t, this.bpm);
}

final heartRateBufferProvider =
    StateNotifierProvider<HeartRateBuffer, List<HeartRateSample>>(
  (ref) => HeartRateBuffer(),
);
