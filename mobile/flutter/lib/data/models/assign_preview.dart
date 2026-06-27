/// Typed models for the live "schedule preview + overlap" experience that
/// backs the START PROGRAM bottom sheet.
///
/// These mirror the `POST /program-templates/assign-preview` response. They are
/// parse-only (no `toJson`) — the sheet sends the assign args directly. Every
/// `fromJson` is defensive about loose JSON (ints arriving as strings/doubles,
/// missing keys) so a partial backend payload renders what it can rather than
/// throwing into the sheet. We NEVER substitute mock data — absent fields just
/// surface as empty lists / zeroes.
library;

/// Coerce a loose JSON number/string into an int, defaulting to [fallback].
int _toInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? fallback;
  return fallback;
}

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

String _toStr(dynamic v) => v?.toString() ?? '';

/// How a scheduled day lands on the user's existing calendar.
/// "replace" = REPLACES an existing primary/AI workout on that date,
/// "stack"   = runs alongside / stacks on top of what's already there,
/// "add"     = a brand-new training day with nothing there before.
enum PreviewResolution { add, stack, replace }

PreviewResolution _resolutionFrom(dynamic raw) {
  switch (_toStr(raw).toLowerCase()) {
    case 'replace':
      return PreviewResolution.replace;
    case 'stack':
      return PreviewResolution.stack;
    default:
      return PreviewResolution.add;
  }
}

/// One scheduled training day inside a [PreviewWeek].
class PreviewDay {
  final String date; // YYYY-MM-DD
  final int weekday; // 0=Mon..6=Sun
  final String weekdayName; // "Mon"
  final String sessionName; // "Upper A"
  final String workoutType; // "strength"
  final int exercisesCount;
  final String intensityMode; // "normal" | "deload"
  final PreviewResolution resolution;

  const PreviewDay({
    required this.date,
    required this.weekday,
    required this.weekdayName,
    required this.sessionName,
    required this.workoutType,
    required this.exercisesCount,
    required this.intensityMode,
    required this.resolution,
  });

  bool get isDeload => intensityMode.toLowerCase() == 'deload';

  factory PreviewDay.fromJson(Map<String, dynamic> json) {
    return PreviewDay(
      date: _toStr(json['date']),
      weekday: _toInt(json['weekday']),
      weekdayName: _toStr(json['weekday_name']),
      sessionName: _toStr(json['session_name']),
      workoutType: _toStr(json['workout_type']),
      exercisesCount: _toInt(json['exercises_count']),
      intensityMode: _toStr(json['intensity_mode']),
      resolution: _resolutionFrom(json['resolution']),
    );
  }
}

/// One program week with its training days.
class PreviewWeek {
  final int weekNumber;
  final bool isDeload;
  final List<PreviewDay> days;

  const PreviewWeek({
    required this.weekNumber,
    required this.isDeload,
    required this.days,
  });

  factory PreviewWeek.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final days = <PreviewDay>[];
    if (rawDays is List) {
      for (final d in rawDays) {
        if (d is Map) {
          days.add(PreviewDay.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }
    return PreviewWeek(
      weekNumber: _toInt(json['week_number']),
      isDeload: _toBool(json['is_deload']),
      days: days,
    );
  }
}

/// A date where this program collides with something already on the calendar.
class PreviewCollision {
  final String date; // YYYY-MM-DD
  final int weekday; // 0=Mon..6=Sun
  final String weekdayName; // "Wed"
  final PreviewResolution resolution;
  final String source; // "program" | "ai" | "ai_planned"
  final String existingName; // "Power Upper Body"
  final String existingSlot; // "primary" | "addon"

  const PreviewCollision({
    required this.date,
    required this.weekday,
    required this.weekdayName,
    required this.resolution,
    required this.source,
    required this.existingName,
    required this.existingSlot,
  });

  factory PreviewCollision.fromJson(Map<String, dynamic> json) {
    return PreviewCollision(
      date: _toStr(json['date']),
      weekday: _toInt(json['weekday']),
      weekdayName: _toStr(json['weekday_name']),
      resolution: _resolutionFrom(json['resolution']),
      source: _toStr(json['source']),
      existingName: _toStr(json['existing_name']),
      existingSlot: _toStr(json['existing_slot']),
    );
  }
}

/// An existing assignment that starting this program (with Replace) ends.
class PreviewReplaceEnd {
  final String assignmentId;
  final String name;
  final List<int> weekdays; // 0=Mon..6=Sun

  const PreviewReplaceEnd({
    required this.assignmentId,
    required this.name,
    required this.weekdays,
  });

  factory PreviewReplaceEnd.fromJson(Map<String, dynamic> json) {
    final rawDays = json['weekdays'];
    final weekdays = <int>[];
    if (rawDays is List) {
      for (final w in rawDays) {
        weekdays.add(_toInt(w));
      }
    }
    return PreviewReplaceEnd(
      assignmentId: _toStr(json['assignment_id']),
      name: _toStr(json['name']),
      weekdays: weekdays,
    );
  }
}

/// Aggregate impact counts across the whole preview.
class PreviewImpact {
  final int replaceCount;
  final int stackCount;
  final int newCount;

  const PreviewImpact({
    required this.replaceCount,
    required this.stackCount,
    required this.newCount,
  });

  factory PreviewImpact.fromJson(Map<String, dynamic> json) {
    return PreviewImpact(
      replaceCount: _toInt(json['replace_count']),
      stackCount: _toInt(json['stack_count']),
      newCount: _toInt(json['new_count']),
    );
  }

  static const empty = PreviewImpact(replaceCount: 0, stackCount: 0, newCount: 0);
}

/// Full response of `POST /program-templates/assign-preview` — a deterministic,
/// LLM-free projection of what assigning this program will schedule and overlap.
class AssignPreview {
  final String programId;
  final String programName;
  final int durationWeeks;
  final int sessionsPerWeek;
  final int totalWorkouts;
  final String startDate; // YYYY-MM-DD
  final String slot; // "primary" | "addon"

  /// Whether the chosen training-days actually drive scheduling. False for
  /// consecutive-day programs (e.g. a 30-day daily challenge), where the
  /// weekday picker is meaningless and should be hidden.
  final bool respectsTrainingDays;
  final List<PreviewWeek> weeks;
  final List<PreviewCollision> collisions;
  final List<PreviewReplaceEnd> replaceEnds;
  final PreviewImpact impact;
  final String summary;

  const AssignPreview({
    required this.programId,
    required this.programName,
    required this.durationWeeks,
    required this.sessionsPerWeek,
    required this.totalWorkouts,
    required this.startDate,
    required this.slot,
    required this.respectsTrainingDays,
    required this.weeks,
    required this.collisions,
    required this.replaceEnds,
    required this.impact,
    required this.summary,
  });

  /// Fast lookup: existing-name keyed by date, for annotating day rows with the
  /// thing they collide with (e.g. "↔ Power Upper Body").
  Map<String, PreviewCollision> get collisionsByDate {
    final map = <String, PreviewCollision>{};
    for (final c in collisions) {
      if (c.date.isNotEmpty) map[c.date] = c;
    }
    return map;
  }

  factory AssignPreview.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
        dynamic raw, T Function(Map<String, dynamic>) fromJson) {
      final out = <T>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) out.add(fromJson(Map<String, dynamic>.from(e)));
        }
      }
      return out;
    }

    final impactRaw = json['impact'];
    return AssignPreview(
      programId: _toStr(json['program_id']),
      programName: _toStr(json['program_name']),
      durationWeeks: _toInt(json['duration_weeks']),
      sessionsPerWeek: _toInt(json['sessions_per_week']),
      totalWorkouts: _toInt(json['total_workouts']),
      startDate: _toStr(json['start_date']),
      slot: _toStr(json['slot']),
      // Default true when absent so normal programs keep showing the picker.
      respectsTrainingDays: json['respects_training_days'] == null
          ? true
          : _toBool(json['respects_training_days']),
      weeks: parseList(json['weeks'], PreviewWeek.fromJson),
      collisions: parseList(json['collisions'], PreviewCollision.fromJson),
      replaceEnds: parseList(json['replace_ends'], PreviewReplaceEnd.fromJson),
      impact: impactRaw is Map
          ? PreviewImpact.fromJson(Map<String, dynamic>.from(impactRaw))
          : PreviewImpact.empty,
      summary: _toStr(json['summary']),
    );
  }
}
