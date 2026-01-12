import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/wearable_service.dart';

/// Provides real-time heart rate data during workouts from WearOS watch.
/// Listens to both 'live_heart_rate' and 'health_data_received' events.
final liveHeartRateProvider = StreamProvider.autoDispose<HeartRateReading?>((ref) {
  return WearableService.instance.events
      .where((e) =>
          e.type == WearableEventTypes.liveHeartRate ||
          e.type == WearableEventTypes.healthDataReceived)
      .map((event) {
        final data = event.data;
        // Handle both formats: 'bpm' from live_heart_rate and 'heartRateBpm' from health_data
        final bpm = data['bpm'] ?? data['heartRateBpm'] ?? data['value'];
        if (bpm != null) {
          final bpmInt = bpm is int ? bpm : (bpm as num).toInt();
          return HeartRateReading(
            bpm: bpmInt,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              data['timestamp'] as int? ??
                  data['startTime'] as int? ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
        return null;
      })
      .where((reading) => reading != null);
});

/// Accumulates heart rate readings during a workout session.
/// Use this to build the heart rate graph after workout completion.
final workoutHeartRateHistoryProvider = StateNotifierProvider.autoDispose<
    WorkoutHeartRateHistoryNotifier, List<HeartRateReading>>((ref) {
  return WorkoutHeartRateHistoryNotifier(ref);
});

/// State notifier that accumulates heart rate readings during a workout.
class WorkoutHeartRateHistoryNotifier extends StateNotifier<List<HeartRateReading>> {
  final Ref ref;
  StreamSubscription? _subscription;

  WorkoutHeartRateHistoryNotifier(this.ref) : super([]) {
    // Listen to live heart rate updates and accumulate them
    _subscription = WearableService.instance.events
        .where((e) =>
            e.type == WearableEventTypes.liveHeartRate ||
            e.type == WearableEventTypes.healthDataReceived)
        .listen((event) {
      final data = event.data;
      final bpm = data['bpm'] ?? data['heartRateBpm'] ?? data['value'];
      if (bpm != null) {
        final bpmInt = bpm is int ? bpm : (bpm as num).toInt();
        final reading = HeartRateReading(
          bpm: bpmInt,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            data['timestamp'] as int? ??
                data['startTime'] as int? ??
                DateTime.now().millisecondsSinceEpoch,
          ),
        );
        state = [...state, reading];
      }
    });
  }

  /// Get heart rate statistics for the current session.
  HeartRateStats? getStats() {
    if (state.isEmpty) return null;
    final bpms = state.map((r) => r.bpm).toList();
    return HeartRateStats(
      min: bpms.reduce((a, b) => a < b ? a : b),
      max: bpms.reduce((a, b) => a > b ? a : b),
      avg: (bpms.reduce((a, b) => a + b) / bpms.length).round(),
      samples: state,
    );
  }

  /// Clear all accumulated readings (call when starting a new workout).
  void clear() => state = [];

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Single heart rate reading with timestamp.
class HeartRateReading {
  final int bpm;
  final DateTime timestamp;

  HeartRateReading({required this.bpm, required this.timestamp});

  @override
  String toString() => 'HeartRateReading(bpm: $bpm, timestamp: $timestamp)';
}

/// Heart rate statistics for a workout session.
class HeartRateStats {
  final int min;
  final int max;
  final int avg;
  final List<HeartRateReading> samples;

  HeartRateStats({
    required this.min,
    required this.max,
    required this.avg,
    required this.samples,
  });

  @override
  String toString() => 'HeartRateStats(min: $min, max: $max, avg: $avg, samples: ${samples.length})';
}

/// Get heart rate zone based on BPM and max heart rate.
/// Uses standard 6-zone model for heart rate training.
HeartRateZone getHeartRateZone(int bpm, {int maxHr = 190}) {
  final percentage = (bpm / maxHr) * 100;

  if (percentage < 50) {
    return HeartRateZone.rest;
  } else if (percentage < 60) {
    return HeartRateZone.warmUp;
  } else if (percentage < 70) {
    return HeartRateZone.fatBurn;
  } else if (percentage < 80) {
    return HeartRateZone.cardio;
  } else if (percentage < 90) {
    return HeartRateZone.peak;
  } else {
    return HeartRateZone.max;
  }
}

/// Heart rate training zones.
enum HeartRateZone {
  rest,
  warmUp,
  fatBurn,
  cardio,
  peak,
  max;

  String get name {
    switch (this) {
      case HeartRateZone.rest:
        return 'Rest';
      case HeartRateZone.warmUp:
        return 'Warm Up';
      case HeartRateZone.fatBurn:
        return 'Fat Burn';
      case HeartRateZone.cardio:
        return 'Cardio';
      case HeartRateZone.peak:
        return 'Peak';
      case HeartRateZone.max:
        return 'Max';
    }
  }

  /// Zone color in hex (0xAARRGGBB format).
  int get colorValue {
    switch (this) {
      case HeartRateZone.rest:
        return 0xFF4CAF50; // Green
      case HeartRateZone.warmUp:
        return 0xFF8BC34A; // Light Green
      case HeartRateZone.fatBurn:
        return 0xFFFFEB3B; // Yellow
      case HeartRateZone.cardio:
        return 0xFFFF9800; // Orange
      case HeartRateZone.peak:
        return 0xFFF44336; // Red
      case HeartRateZone.max:
        return 0xFF9C27B0; // Purple
    }
  }

  /// Zone percentage range as a string.
  String get percentageRange {
    switch (this) {
      case HeartRateZone.rest:
        return '0-50%';
      case HeartRateZone.warmUp:
        return '50-60%';
      case HeartRateZone.fatBurn:
        return '60-70%';
      case HeartRateZone.cardio:
        return '70-80%';
      case HeartRateZone.peak:
        return '80-90%';
      case HeartRateZone.max:
        return '90-100%';
    }
  }
}
