import 'workout.dart';

/// Program provenance carried on a program-sourced workout.
///
/// The backend `/workouts/today` tags each program-sourced workout with
/// `program_id`, `program_name`, `program_week`, `program_slot`
/// (`primary`|`addon`), and `assignment_id`. The [Workout] model is codegen-
/// locked (`workout.g.dart` — we must NOT run build_runner, see
/// `project_codegen_gotcha`), so these tags ride inside the free-form
/// `generation_metadata` map (the same channel `challenge_exercise` already
/// uses). This class is the typed view over that sub-map.
class WorkoutProgramContext {
  final String? programId;
  final String? programName;
  final int? programWeek;

  /// `primary` drives the home hero; `addon` stacks on top of it.
  final String slot;

  final String? assignmentId;

  /// Total program length in weeks, when the backend includes it. Drives the
  /// "Week X of Y" banner.
  final int? durationWeeks;

  const WorkoutProgramContext({
    this.programId,
    this.programName,
    this.programWeek,
    this.slot = 'primary',
    this.assignmentId,
    this.durationWeeks,
  });

  bool get isAddon => slot.toLowerCase() == 'addon';
  bool get isPrimary => !isAddon;

  /// "Week 3 · Push Pull Legs" (or "Week 3 of 8 · …" when total is known).
  /// Falls back gracefully when fields are missing.
  String banner() {
    final parts = <String>[];
    final w = programWeek;
    if (w != null && w > 0) {
      final total = durationWeeks;
      parts.add(total != null && total > 0 ? 'Week $w of $total' : 'Week $w');
    }
    final name = programName?.trim();
    if (name != null && name.isNotEmpty) parts.add(name);
    return parts.join(' · ');
  }

  /// Whether there's anything worth rendering (a name and/or a week number).
  bool get hasContent =>
      (programName != null && programName!.trim().isNotEmpty) ||
      (programWeek != null && programWeek! > 0);

  /// Build the generation-metadata sub-map so a [Workout] can carry these tags
  /// through `toWorkout()` / caching. Only non-null fields are written.
  Map<String, dynamic> toMetadata() => {
        if (programId != null) 'program_id': programId,
        if (programName != null) 'program_name': programName,
        if (programWeek != null) 'program_week': programWeek,
        'program_slot': slot,
        if (assignmentId != null) 'assignment_id': assignmentId,
        if (durationWeeks != null) 'program_duration_weeks': durationWeeks,
      };

  /// Parse from a raw JSON map (either a `/today` workout row or a
  /// `generation_metadata` sub-map). Tolerant of both top-level keys and a
  /// nested `generation_metadata` blob. Returns null when no program tag is
  /// present at all.
  static WorkoutProgramContext? fromAnyJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    // Prefer top-level tags (the /today row), fall back to the nested
    // generation_metadata blob.
    final meta = json['generation_metadata'];
    final src = <String, dynamic>{
      if (meta is Map) ...Map<String, dynamic>.from(meta),
      ...json, // top-level wins over nested
    };
    final id = src['program_id']?.toString();
    final name = src['program_name']?.toString();
    final week = _asInt(src['program_week']);
    final assignmentId = src['assignment_id']?.toString();
    final slot = (src['program_slot']?.toString() ?? 'primary');
    final duration =
        _asInt(src['program_duration_weeks'] ?? src['duration_weeks']);
    final hasAny = (id != null && id.isNotEmpty) ||
        (name != null && name.isNotEmpty) ||
        week != null ||
        (assignmentId != null && assignmentId.isNotEmpty);
    if (!hasAny) return null;
    return WorkoutProgramContext(
      programId: id,
      programName: name,
      programWeek: week,
      slot: slot,
      assignmentId: assignmentId,
      durationWeeks: duration,
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}

/// Read the program provenance off a [Workout]. Returns null for ad-hoc / AI /
/// synced workouts that carry no program tag.
extension WorkoutProgramContextX on Workout {
  WorkoutProgramContext? get programContext =>
      WorkoutProgramContext.fromAnyJson(generationMetadata);

  /// True when this workout came from an enrolled program.
  bool get isFromProgram => programContext?.programId != null;
}
