import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ble_heart_rate_service.dart';
import '../../data/services/wearable_service.dart';

/// Source of a heart rate reading.
enum HeartRateSource { wearOs, bleMonitor }

/// Merged live heart rate provider.
///
/// Streams [HeartRateReading] from both WearOS Data Layer and BLE HR monitor.
/// **BLE takes priority**: when both sources are active, WearOS readings are
/// suppressed while BLE readings arrive within the last 10 seconds.
final liveHeartRateProvider = StreamProvider.autoDispose<HeartRateReading?>((ref) {
  final controller = StreamController<HeartRateReading?>();
  DateTime? lastBleReading;

  // --- BLE Heart Rate stream ---
  final bleSub = BleHeartRateService.instance.heartRateStream.listen((bleReading) {
    lastBleReading = DateTime.now();
    controller.add(HeartRateReading(
      bpm: bleReading.bpm,
      timestamp: bleReading.timestamp,
      source: HeartRateSource.bleMonitor,
    ));
  });

  // --- WearOS stream (existing logic, lower priority) ---
  final wearSub = WearableService.instance.events
      .where((e) =>
          e.type == WearableEventTypes.liveHeartRate ||
          e.type == WearableEventTypes.healthDataReceived)
      .listen((event) {
    // Suppress WearOS if BLE reading was received in last 10 seconds
    if (lastBleReading != null &&
        DateTime.now().difference(lastBleReading!).inSeconds < 10) {
      return;
    }

    final data = event.data;
    final bpm = data['bpm'] ?? data['heartRateBpm'] ?? data['value'];
    if (bpm != null) {
      final bpmInt = bpm is int ? bpm : (bpm as num).toInt();
      controller.add(HeartRateReading(
        bpm: bpmInt,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          data['timestamp'] as int? ??
              data['startTime'] as int? ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        source: HeartRateSource.wearOs,
      ));
    }
  });

  ref.onDispose(() {
    bleSub.cancel();
    wearSub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Accumulates heart rate readings during a workout session.
/// Use this to build the heart rate graph after workout completion.
final workoutHeartRateHistoryProvider = StateNotifierProvider.autoDispose<
    WorkoutHeartRateHistoryNotifier, List<HeartRateReading>>((ref) {
  return WorkoutHeartRateHistoryNotifier(ref);
});

/// State notifier that accumulates heart rate readings during a workout.
/// Listens to both WearOS and BLE streams with BLE priority.
class WorkoutHeartRateHistoryNotifier extends StateNotifier<List<HeartRateReading>> {
  final Ref ref;
  StreamSubscription? _wearSubscription;
  StreamSubscription? _bleSubscription;
  DateTime? _lastBleReading;

  WorkoutHeartRateHistoryNotifier(this.ref) : super([]) {
    // BLE HR stream
    _bleSubscription = BleHeartRateService.instance.heartRateStream.listen((bleReading) {
      _lastBleReading = DateTime.now();
      final reading = HeartRateReading(
        bpm: bleReading.bpm,
        timestamp: bleReading.timestamp,
        source: HeartRateSource.bleMonitor,
      );
      state = [...state, reading];
    });

    // WearOS stream (lower priority)
    _wearSubscription = WearableService.instance.events
        .where((e) =>
            e.type == WearableEventTypes.liveHeartRate ||
            e.type == WearableEventTypes.healthDataReceived)
        .listen((event) {
      if (_lastBleReading != null &&
          DateTime.now().difference(_lastBleReading!).inSeconds < 10) {
        return;
      }
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
          source: HeartRateSource.wearOs,
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
    _wearSubscription?.cancel();
    _bleSubscription?.cancel();
    super.dispose();
  }
}

/// Single heart rate reading with timestamp.
class HeartRateReading {
  final int bpm;
  final DateTime timestamp;
  final HeartRateSource? source;

  HeartRateReading({required this.bpm, required this.timestamp, this.source});

  @override
  String toString() => 'HeartRateReading(bpm: $bpm, timestamp: $timestamp, source: $source)';
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

  /// Beginner-friendly description of what this zone means.
  String get description {
    switch (this) {
      case HeartRateZone.rest:
        return 'Recovery pace - very easy breathing';
      case HeartRateZone.warmUp:
        return 'Light activity - easy conversation';
      case HeartRateZone.fatBurn:
        return 'Fat burning zone - comfortable pace, can hold a conversation';
      case HeartRateZone.cardio:
        return 'Building fitness - breathing harder, can say short sentences';
      case HeartRateZone.peak:
        return 'Performance zone - heavy breathing, can only say a few words';
      case HeartRateZone.max:
        return 'Maximum effort - cannot talk, use sparingly';
    }
  }

  /// Short label for the zone (for compact display).
  String get shortLabel {
    switch (this) {
      case HeartRateZone.rest:
        return 'Rest';
      case HeartRateZone.warmUp:
        return 'Warm';
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

  /// Percentage of calories from fat burned in this zone (approximate).
  double get fatCaloriePercent {
    switch (this) {
      case HeartRateZone.rest:
      case HeartRateZone.warmUp:
        return 0.85; // 85% from fat
      case HeartRateZone.fatBurn:
        return 0.65; // 65% from fat - optimal for weight loss
      case HeartRateZone.cardio:
        return 0.45; // 45% from fat
      case HeartRateZone.peak:
        return 0.30; // 30% from fat
      case HeartRateZone.max:
        return 0.20; // 20% from fat
    }
  }
}

// ============================================================================
// FITNESS CALCULATIONS
// ============================================================================

/// Calculate maximum heart rate based on age.
/// Uses the updated formula: MHR = 208 - (0.7 × age)
/// More accurate than the old 220 - age formula.
int calculateMaxHR(int age) => (208 - (0.7 * age)).round();

/// Calculate VO2 Max using the Heart Rate Ratio method.
/// Formula: VO2 max = 15.3 × (maxHR / restingHR)
/// Returns null if restingHR is invalid.
double? estimateVO2Max(int maxHR, int? restingHR) {
  if (restingHR == null || restingHR <= 0 || restingHR >= maxHR) return null;
  return 15.3 * (maxHR / restingHR);
}

/// Get fitness level label based on VO2 Max value.
String getVO2MaxFitnessLevel(double vo2Max) {
  if (vo2Max < 30) return 'Poor';
  if (vo2Max < 40) return 'Fair';
  if (vo2Max < 50) return 'Good';
  if (vo2Max < 60) return 'Excellent';
  return 'Elite';
}

/// Calculate Aerobic Training Effect (1.0 - 5.0 scale).
/// Based on time spent in different intensity zones.
double calculateAerobicTrainingEffect(
  List<HeartRateReading> readings,
  int maxHR,
  int durationMinutes,
) {
  if (readings.isEmpty || durationMinutes <= 0) return 0;

  // Calculate time in each intensity zone
  int highIntensityCount = 0; // >85% max HR
  int moderateIntensityCount = 0; // 70-85% max HR

  for (final r in readings) {
    final intensity = r.bpm / maxHR;
    if (intensity > 0.85) {
      highIntensityCount++;
    } else if (intensity > 0.70) {
      moderateIntensityCount++;
    }
  }

  // Convert counts to approximate minutes
  final readingsPerMinute = readings.length / durationMinutes;
  final highIntensityMinutes = readingsPerMinute > 0
      ? highIntensityCount / readingsPerMinute
      : 0.0;
  final moderateIntensityMinutes = readingsPerMinute > 0
      ? moderateIntensityCount / readingsPerMinute
      : 0.0;

  // Calculate Training Effect score
  double te = 1.0; // Base maintenance level

  // High intensity contribution (biggest impact)
  te += (highIntensityMinutes / 10) * 1.5;

  // Moderate intensity contribution
  te += (moderateIntensityMinutes / 15) * 0.8;

  // Duration bonus for longer workouts
  if (durationMinutes > 45) te += 0.3;
  if (durationMinutes > 60) te += 0.2;

  return te.clamp(1.0, 5.0);
}

/// Get Training Effect label based on score.
String getTrainingEffectLabel(double te) {
  if (te < 2.0) return 'Minor';
  if (te < 3.0) return 'Maintaining';
  if (te < 4.0) return 'Improving';
  if (te < 5.0) return 'Highly Improving';
  return 'Overreaching';
}

/// Calculate Anaerobic Training Effect (1.0 - 5.0 scale).
/// Based on number of high-intensity intervals (>90% max HR).
double calculateAnaerobicTrainingEffect(
  List<HeartRateReading> readings,
  int maxHR,
) {
  if (readings.isEmpty) return 0;

  // Count intervals where HR exceeded 90% max
  int peakIntervals = 0;
  bool wasInPeak = false;

  for (final r in readings) {
    final isInPeak = r.bpm / maxHR > 0.90;
    if (isInPeak && !wasInPeak) {
      peakIntervals++;
    }
    wasInPeak = isInPeak;
  }

  // Anaerobic TE based on number of peak efforts
  if (peakIntervals == 0) return 0;
  if (peakIntervals < 3) return 1.0;
  if (peakIntervals < 6) return 2.0;
  if (peakIntervals < 10) return 3.0;
  if (peakIntervals < 15) return 4.0;
  return 5.0;
}

/// Calculate EPOC (afterburn) percentage based on workout intensity.
/// Returns the percentage of extra calories burned after workout.
double estimateEPOCPercent(int avgHR, int maxHR) {
  if (maxHR <= 0) return 0;
  final intensity = avgHR / maxHR;
  if (intensity > 0.85) return 0.15; // 15% extra calories
  if (intensity > 0.75) return 0.08; // 8% extra
  if (intensity > 0.65) return 0.04; // 4% extra
  return 0.02; // 2% extra for low intensity
}

/// Calculate zone breakdown from heart rate readings.
/// Returns a map of zone to duration in seconds.
Map<HeartRateZone, int> calculateZoneBreakdown(
  List<HeartRateReading> readings,
  int maxHR,
) {
  final breakdown = <HeartRateZone, int>{};
  for (final zone in HeartRateZone.values) {
    breakdown[zone] = 0;
  }

  if (readings.length < 2) return breakdown;

  // Estimate time per reading (assume even distribution)
  final totalDuration = readings.last.timestamp
      .difference(readings.first.timestamp)
      .inSeconds;
  final secondsPerReading = readings.length > 1
      ? totalDuration / (readings.length - 1)
      : 1.0;

  for (final r in readings) {
    final zone = getHeartRateZone(r.bpm, maxHr: maxHR);
    breakdown[zone] = breakdown[zone]! + secondsPerReading.round();
  }

  return breakdown;
}

/// Find peak indices (local maxima) in heart rate readings.
/// Returns indices of readings that are significant peaks.
List<int> findPeaks(
  List<HeartRateReading> readings, {
  int windowSize = 5,
  int minDifference = 10,
}) {
  if (readings.length < windowSize * 2 + 1) return [];

  final peaks = <int>[];

  for (int i = windowSize; i < readings.length - windowSize; i++) {
    final current = readings[i].bpm;
    bool isPeak = true;

    // Check if current is greater than all neighbors in window
    for (int j = i - windowSize; j <= i + windowSize; j++) {
      if (j != i && readings[j].bpm >= current) {
        isPeak = false;
        break;
      }
    }

    // Also check minimum difference from neighbors
    if (isPeak) {
      final leftAvg = readings
          .sublist(i - windowSize, i)
          .map((r) => r.bpm)
          .reduce((a, b) => a + b) / windowSize;
      final rightAvg = readings
          .sublist(i + 1, i + windowSize + 1)
          .map((r) => r.bpm)
          .reduce((a, b) => a + b) / windowSize;

      if (current - leftAvg < minDifference || current - rightAvg < minDifference) {
        isPeak = false;
      }
    }

    if (isPeak) peaks.add(i);
  }

  return peaks;
}

/// Find valley indices (local minima) in heart rate readings.
/// Returns indices of readings that are significant valleys (rest periods).
List<int> findValleys(
  List<HeartRateReading> readings, {
  int windowSize = 5,
  int minDifference = 10,
}) {
  if (readings.length < windowSize * 2 + 1) return [];

  final valleys = <int>[];

  for (int i = windowSize; i < readings.length - windowSize; i++) {
    final current = readings[i].bpm;
    bool isValley = true;

    // Check if current is less than all neighbors in window
    for (int j = i - windowSize; j <= i + windowSize; j++) {
      if (j != i && readings[j].bpm <= current) {
        isValley = false;
        break;
      }
    }

    // Also check minimum difference from neighbors
    if (isValley) {
      final leftAvg = readings
          .sublist(i - windowSize, i)
          .map((r) => r.bpm)
          .reduce((a, b) => a + b) / windowSize;
      final rightAvg = readings
          .sublist(i + 1, i + windowSize + 1)
          .map((r) => r.bpm)
          .reduce((a, b) => a + b) / windowSize;

      if (leftAvg - current < minDifference || rightAvg - current < minDifference) {
        isValley = false;
      }
    }

    if (isValley) valleys.add(i);
  }

  return valleys;
}

/// Extended heart rate statistics including fitness metrics.
class ExtendedHeartRateStats {
  final int min;
  final int max;
  final int avg;
  final List<HeartRateReading> samples;
  final int maxHR;
  final int? restingHR;
  final int durationMinutes;

  ExtendedHeartRateStats({
    required this.min,
    required this.max,
    required this.avg,
    required this.samples,
    required this.maxHR,
    this.restingHR,
    required this.durationMinutes,
  });

  /// Estimated VO2 Max (null if resting HR not available).
  double? get vo2Max => estimateVO2Max(maxHR, restingHR);

  /// VO2 Max fitness level label.
  String? get vo2MaxLevel => vo2Max != null ? getVO2MaxFitnessLevel(vo2Max!) : null;

  /// Aerobic Training Effect (1.0 - 5.0).
  double get aerobicTE => calculateAerobicTrainingEffect(samples, maxHR, durationMinutes);

  /// Aerobic Training Effect label.
  String get aerobicTELabel => getTrainingEffectLabel(aerobicTE);

  /// Anaerobic Training Effect (0 - 5.0).
  double get anaerobicTE => calculateAnaerobicTrainingEffect(samples, maxHR);

  /// Anaerobic Training Effect label.
  String get anaerobicTELabel => anaerobicTE > 0 ? getTrainingEffectLabel(anaerobicTE) : 'None';

  /// EPOC (afterburn) percentage.
  double get epocPercent => estimateEPOCPercent(avg, maxHR);

  /// Zone breakdown (zone -> seconds).
  Map<HeartRateZone, int> get zoneBreakdown => calculateZoneBreakdown(samples, maxHR);

  /// Time in fat burn zone (seconds).
  int get fatBurnSeconds => zoneBreakdown[HeartRateZone.fatBurn] ?? 0;

  /// Time in fat burn zone (minutes).
  double get fatBurnMinutes => fatBurnSeconds / 60;

  /// Peak indices in readings.
  List<int> get peakIndices => findPeaks(samples);

  /// Valley indices in readings.
  List<int> get valleyIndices => findValleys(samples);
}
