// Exercise tracking-metric classifier.
//
// Decides HOW an exercise is logged — by load, bodyweight reps, time, or
// distance — for ANY exercise: curated-program, AI-generated, or custom. The
// active-workout screens use this to pick the right input UI and to suppress
// the phantom "10 kg × 1" default that cardio / functional / timed / bodyweight
// moves used to show.
//
// Precedence (most-trusted signal first):
//   1. Backend hint  — `tracking_type` emitted by the workout serializer.
//   2. Distance      — a distance machine / carry / sled / run, an explicit
//                      `distance_meters`, or a distance-unit target string.
//   3. Time          — `is_timed` / hold / duration, or a time-unit target.
//   4. Bodyweight    — bodyweight/none equipment, or a known bodyweight rep move.
//   5. Weight        — everything else (loaded lifts).
//
// The frontend lists are a backstop: once the backend emits `tracking_type` /
// `distance_meters` (and the exercise_library carries correct equipment /
// is_timed), (1) short-circuits and this heuristic rarely runs — but it keeps
// the app correct offline and for un-tagged custom moves.

/// The metric an exercise is logged by.
enum TrackingMetric {
  /// Load × reps (barbell, dumbbell, machine, cable).
  weight,

  /// Reps only — no weight column (burpees, push-ups, air squats).
  bodyweight,

  /// A hold / duration timer (plank, wall sit, dead hang, cardio-by-time).
  time,

  /// Distance in meters, optionally with a timer (SkiErg, row erg, sled,
  /// loaded carries, runs).
  distance,
}

extension TrackingMetricX on TrackingMetric {
  bool get isWeight => this == TrackingMetric.weight;
  bool get isBodyweight => this == TrackingMetric.bodyweight;
  bool get isTime => this == TrackingMetric.time;
  bool get isDistance => this == TrackingMetric.distance;

  /// True when the move has NO external load to log (everything except weight).
  bool get hasNoWeight => this != TrackingMetric.weight;
}

/// A parsed target string, e.g. "1000 m" → (distance, 1000, "m").
class TargetSpec {
  final TrackingMetric metric;

  /// Numeric magnitude in the metric's canonical unit:
  ///   distance → meters · time → seconds · bodyweight → reps · weight → reps.
  final num? value;
  const TargetSpec(this.metric, this.value);
}

class ExerciseTrackingMetric {
  ExerciseTrackingMetric._();

  // ── Name fragments (lowercased, substring match) ────────────────────────

  /// Cardio machines + sled + loaded carries + distance running → distance.
  static const List<String> _distanceFragments = [
    'skierg', 'ski erg', 'ski-erg',
    'rowerg', 'row erg', 'rowing machine', 'rowing', 'erg row',
    'sled push', 'sled pull', 'sled drag', 'sled sprint', 'prowler', 'yoke',
    "farmer's carry", 'farmers carry', 'farmer carry', 'farmers walk',
    "farmer's walk", 'loaded carry', 'suitcase carry', 'overhead carry',
    'sandbag carry', 'sandbag lunge', // HYROX sandbag lunges are distance (m)
    'broad jump', 'bear crawl', 'sprint', 'shuttle run', 'beep test',
  ];

  /// Distance-running names that are distance ONLY when measured by distance
  /// (we still let an explicit duration override to time upstream).
  static const List<String> _runFragments = [
    'run', 'jog', 'walk', // qualified below by a distance signal
  ];

  /// Isometric holds / time-based moves.
  static const List<String> _timeFragments = [
    'plank', 'wall sit', 'wall-sit', 'dead hang', 'hollow hold', 'hollow body',
    'l-sit', 'l sit', 'hold', 'isometric', 'static',
    'flutter kick', 'superman hold', 'bridge hold', 'side plank',
  ];

  /// Classic bodyweight rep moves (no external load).
  static const List<String> _bodyweightFragments = [
    'burpee', 'air squat', 'jump squat', 'jumping jack', 'mountain climber',
    'push-up', 'push up', 'pushup', 'pull-up', 'pull up', 'pullup', 'chin-up',
    'chin up', 'sit-up', 'situp', 'sit up', 'crunch', 'box jump', 'tuck jump',
    'high knee', 'butt kick', 'bodyweight squat', 'bodyweight lunge',
    'jumping lunge', 'star jump', 'inchworm', 'bear hold',
    // Med-ball / bar-gymnastics moves logged by reps, not a per-set load
    // (wall balls use a standard fixed med-ball; toes-to-bar is pure
    // bodyweight). Kept narrow on purpose — ambiguous moves that have common
    // weighted variants (dips, chin-ups, thrusters, KB swings) are NOT here so
    // their load is never silently suppressed.
    'wall ball', 'wall-ball', 'toes to bar', 'toes-to-bar', 'knees to elbow',
  ];

  static const List<String> _bodyweightEquipment = [
    'bodyweight', 'body weight', 'none', 'no equipment', 'calisthenics',
  ];

  /// Resolve the tracking metric from the available signals.
  ///
  /// [trackingTypeHint] is the backend `tracking_type` string (preferred).
  /// [distanceMeters] is the backend `distance_meters` target (a strong
  /// distance signal). [repsSpec] is the raw unit-bearing target string.
  static TrackingMetric resolve({
    required String name,
    String? equipment,
    bool isTimed = false,
    int? holdSeconds,
    int? durationSeconds,
    String? trackingTypeHint,
    num? distanceMeters,
    String? repsSpec,
  }) {
    // 1. Trust the backend hint when it's a known value.
    final hint = _fromHint(trackingTypeHint);
    if (hint != null) return hint;

    final n = name.toLowerCase();
    final eq = (equipment ?? '').toLowerCase();
    final specMetric = repsSpec != null ? parseTarget(repsSpec).metric : null;

    final hasDistanceSignal = (distanceMeters != null && distanceMeters > 0) ||
        specMetric == TrackingMetric.distance;

    // 2. Distance: an explicit distance value/unit, or a distance machine /
    //    sled / carry name. A run/jog/walk counts only with a distance signal
    //    (otherwise it's a timed cardio block).
    if (hasDistanceSignal ||
        _matchesAny(n, _distanceFragments) ||
        (_matchesAny(n, _runFragments) && hasDistanceSignal)) {
      return TrackingMetric.distance;
    }

    // 3. Time: holds / durations / a time-unit target.
    if (isTimed ||
        (holdSeconds != null && holdSeconds > 0) ||
        (durationSeconds != null && durationSeconds > 0) ||
        specMetric == TrackingMetric.time ||
        _matchesAny(n, _timeFragments)) {
      return TrackingMetric.time;
    }

    // 4. Bodyweight reps.
    if (_bodyweightEquipment.contains(eq) ||
        _matchesAny(n, _bodyweightFragments)) {
      return TrackingMetric.bodyweight;
    }

    // 5. Default: loaded weight × reps.
    return TrackingMetric.weight;
  }

  static TrackingMetric? _fromHint(String? hint) {
    switch (hint?.toLowerCase().trim()) {
      case 'weight':
      case 'weighted':
        return TrackingMetric.weight;
      case 'bodyweight':
      case 'bw':
      case 'reps':
        return TrackingMetric.bodyweight;
      case 'time':
      case 'timed':
      case 'duration':
      case 'hold':
        return TrackingMetric.time;
      case 'distance':
      case 'cardio':
        return TrackingMetric.distance;
      default:
        return null;
    }
  }

  static bool _matchesAny(String haystack, List<String> fragments) {
    for (final f in fragments) {
      if (haystack.contains(f)) return true;
    }
    return false;
  }

  /// Parse a free-text target into a metric + magnitude.
  /// Examples: "1000 m"→(distance,1000) · "1 km"→(distance,1000) ·
  /// "8 minutes"→(time,480) · "45s hold"→(time,45) · "100 reps"→(bodyweight,100).
  /// Falls back to (weight, parsedInt?) for a plain number.
  static TargetSpec parseTarget(String raw) {
    final s = raw.toLowerCase().trim();
    // Pull the leading number (handles "1000 m", "1.5 km", "30s").
    final numMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(s);
    final value = numMatch != null ? num.tryParse(numMatch.group(1)!) : null;

    // Distance.
    if (s.contains('km') || s.contains('kilome')) {
      return TargetSpec(TrackingMetric.distance,
          value != null ? (value * 1000).round() : null);
    }
    if (RegExp(r'\bm\b').hasMatch(s) ||
        s.contains('meter') ||
        s.contains('metre') ||
        s.endsWith('m')) {
      // Guard against "min"/"minute" being caught by endsWith('m').
      if (!s.contains('min')) {
        return TargetSpec(TrackingMetric.distance, value?.round());
      }
    }

    // Time.
    if (s.contains('hour') || s.contains('hr')) {
      return TargetSpec(
          TrackingMetric.time, value != null ? (value * 3600).round() : null);
    }
    if (s.contains('min')) {
      return TargetSpec(
          TrackingMetric.time, value != null ? (value * 60).round() : null);
    }
    if (s.contains('sec') ||
        RegExp(r'\d+\s*s\b').hasMatch(s) ||
        s.contains('hold')) {
      return TargetSpec(TrackingMetric.time, value?.round());
    }

    // Reps (bodyweight intent).
    if (s.contains('rep')) {
      return TargetSpec(TrackingMetric.bodyweight, value?.round());
    }

    // Plain number → assume reps for a weighted/strength prescription.
    return TargetSpec(TrackingMetric.weight, value?.round());
  }
}
