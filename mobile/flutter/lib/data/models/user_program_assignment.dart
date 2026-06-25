// UserProgramAssignment — a user's active enrollment in a program.
//
// HAND-WRITTEN — NO codegen (see project_codegen_gotcha). Mirrors a
// `user_program_assignments` row (migration 2283 added `assigned_days` + `slot`).
//
// A user can hold MULTIPLE active assignments at once:
//   - one `slot == 'primary'` per training day (drives the home hero), plus
//   - any number of `slot == 'addon'` rows (e.g. a 7-minute core add-on that
//     stacks on top of the primary, or runs on otherwise-empty days).
// `assignedDays` are weekday ints 0=Mon..6=Sun the program occupies.

int? _i(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

bool _b(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  if (v is num) return v != 0;
  return fallback;
}

String? _s(dynamic v) => v?.toString();

List<int> _intList(dynamic v) {
  if (v is List) {
    return v.map(_i).whereType<int>().toList();
  }
  return const [];
}

/// Which lane an assignment occupies on a given day.
enum ProgramSlot { primary, addon }

ProgramSlot _slotFrom(String? raw) =>
    (raw ?? '').toLowerCase() == 'addon' ? ProgramSlot.addon : ProgramSlot.primary;

String _slotTo(ProgramSlot s) => s == ProgramSlot.addon ? 'addon' : 'primary';

class UserProgramAssignment {
  final String id;
  final String? userId;

  /// Legacy link to a `branded_programs` row (mostly null now).
  final String? brandedProgramId;

  /// The editable `user_program_templates` clone this assignment runs from.
  final String? templateId;

  /// The `programs` row the template was cloned from (for re-preview / "similar").
  final String? sourceProgramId;

  /// User-facing name (overrides the program's name when renamed).
  final String? customProgramName;

  /// Display name resolved by the backend (program/editorial name).
  final String? displayName;

  /// 'primary' drives the home hero; 'addon' stacks on top.
  final ProgramSlot slot;

  /// Weekday ints (0=Mon..6=Sun) this program occupies.
  final List<int> assignedDays;

  final String? startedAt;
  final String? targetEndDate;
  final String? completedAt;
  final String? pausedAt;

  final bool isActive;

  /// 'active' | 'paused' | 'completed' | 'abandoned'.
  final String status;

  final int progressPercentage;
  final int workoutsCompleted;
  final int? totalWorkouts;
  final int currentWeek;
  final int? durationWeeks;
  final String? currentPhase;

  /// HYROX race-date support.
  final String? targetRaceDate;
  final String? division;

  const UserProgramAssignment({
    required this.id,
    this.userId,
    this.brandedProgramId,
    this.templateId,
    this.sourceProgramId,
    this.customProgramName,
    this.displayName,
    this.slot = ProgramSlot.primary,
    this.assignedDays = const [],
    this.startedAt,
    this.targetEndDate,
    this.completedAt,
    this.pausedAt,
    this.isActive = true,
    this.status = 'active',
    this.progressPercentage = 0,
    this.workoutsCompleted = 0,
    this.totalWorkouts,
    this.currentWeek = 1,
    this.durationWeeks,
    this.currentPhase,
    this.targetRaceDate,
    this.division,
  });

  factory UserProgramAssignment.fromJson(Map<String, dynamic> json) {
    return UserProgramAssignment(
      id: _s(json['id']) ?? '',
      userId: _s(json['user_id']),
      brandedProgramId: _s(json['branded_program_id']),
      templateId: _s(json['template_id']),
      sourceProgramId: _s(json['source_program_id']),
      customProgramName: _s(json['custom_program_name']),
      displayName: _s(json['display_name']),
      slot: _slotFrom(json['slot'] as String?),
      assignedDays: _intList(json['assigned_days']),
      startedAt: _s(json['started_at']),
      targetEndDate: _s(json['target_end_date']),
      completedAt: _s(json['completed_at']),
      pausedAt: _s(json['paused_at']),
      isActive: _b(json['is_active'], fallback: true),
      status: _s(json['status']) ?? 'active',
      progressPercentage: _i(json['progress_percentage']) ?? 0,
      workoutsCompleted: _i(json['workouts_completed']) ?? 0,
      totalWorkouts: _i(json['total_workouts']),
      currentWeek: _i(json['current_week']) ?? 1,
      durationWeeks: _i(json['duration_weeks']),
      currentPhase: _s(json['current_phase']),
      targetRaceDate: _s(json['target_race_date']),
      division: _s(json['division']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'user_id': userId,
        if (brandedProgramId != null) 'branded_program_id': brandedProgramId,
        if (templateId != null) 'template_id': templateId,
        if (sourceProgramId != null) 'source_program_id': sourceProgramId,
        if (customProgramName != null) 'custom_program_name': customProgramName,
        'slot': _slotTo(slot),
        'assigned_days': assignedDays,
        'is_active': isActive,
        'status': status,
        'progress_percentage': progressPercentage,
        'workouts_completed': workoutsCompleted,
        if (totalWorkouts != null) 'total_workouts': totalWorkouts,
        'current_week': currentWeek,
        if (durationWeeks != null) 'duration_weeks': durationWeeks,
        if (currentPhase != null) 'current_phase': currentPhase,
        if (targetRaceDate != null) 'target_race_date': targetRaceDate,
        if (division != null) 'division': division,
      };

  bool get isAddon => slot == ProgramSlot.addon;
  bool get isPrimary => slot == ProgramSlot.primary;

  /// Best name to show in the UI.
  String get title {
    final c = customProgramName?.trim();
    if (c != null && c.isNotEmpty) return c;
    final d = displayName?.trim();
    if (d != null && d.isNotEmpty) return d;
    return 'Program';
  }

  /// "Week X of Y" when total length is known.
  String get weekLabel {
    final total = durationWeeks;
    if (total != null && total > 0) return 'Week $currentWeek of $total';
    return 'Week $currentWeek';
  }

  /// True when this assignment runs on the given weekday (0=Mon..6=Sun).
  bool coversWeekday(int weekday) => assignedDays.contains(weekday);

  UserProgramAssignment copyWith({
    String? customProgramName,
    String? displayName,
    ProgramSlot? slot,
    List<int>? assignedDays,
    bool? isActive,
    String? status,
    int? progressPercentage,
    int? workoutsCompleted,
    int? currentWeek,
    int? durationWeeks,
  }) {
    return UserProgramAssignment(
      id: id,
      userId: userId,
      brandedProgramId: brandedProgramId,
      templateId: templateId,
      sourceProgramId: sourceProgramId,
      customProgramName: customProgramName ?? this.customProgramName,
      displayName: displayName ?? this.displayName,
      slot: slot ?? this.slot,
      assignedDays: assignedDays ?? this.assignedDays,
      startedAt: startedAt,
      targetEndDate: targetEndDate,
      completedAt: completedAt,
      pausedAt: pausedAt,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      totalWorkouts: totalWorkouts,
      currentWeek: currentWeek ?? this.currentWeek,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      currentPhase: currentPhase,
      targetRaceDate: targetRaceDate,
      division: division,
    );
  }
}
