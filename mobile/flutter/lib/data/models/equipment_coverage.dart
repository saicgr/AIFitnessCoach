import 'package:flutter/foundation.dart';

/// Result of `GET /program-templates/library/{id}/equipment-coverage` — a
/// pre-flight check of how well a curated program's required equipment matches
/// the user's selected gym profile. Computed server-side with the SAME detection
/// the assign-time equipment-fit pass uses, so the warning never disagrees with
/// what Start actually swaps.
@immutable
class EquipmentCoverage {
  /// 'covered'  — every prescribed movement fits the user's gear (or a full-gym
  ///              environment is assumed).
  /// 'gaps'     — the program needs equipment the profile lacks.
  /// 'unknown'  — we can't tell (no equipment set on a non-commercial profile);
  ///              show a soft "add your equipment" nudge, never a false warning.
  final String status;

  /// Percentage of prescribed exercises the user can do as written (0–100).
  final int coveragePct;
  final int totalExercises;

  /// Distinct equipment slugs the program references (e.g. barbell, cable).
  final List<String> requiredEquipment;

  /// Equipment slugs the program needs that the profile lacks.
  final List<String> missingEquipment;

  /// How many prescribed exercises would be swapped to fit the profile.
  final int swappableCount;

  /// Mismatches with no safe replacement (currently always 0 — reserved).
  final int unswappableCount;

  /// True when every gap can be auto-swapped.
  final bool fullyCoverable;

  /// The gym profile the check was run against (echoed back by the server).
  final String? gymProfileId;

  const EquipmentCoverage({
    required this.status,
    required this.coveragePct,
    required this.totalExercises,
    required this.requiredEquipment,
    required this.missingEquipment,
    required this.swappableCount,
    required this.unswappableCount,
    required this.fullyCoverable,
    this.gymProfileId,
  });

  bool get hasGaps => status == 'gaps';
  bool get isUnknown => status == 'unknown';
  bool get isCovered => status == 'covered';

  factory EquipmentCoverage.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    List<String> toStrList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
      return const [];
    }

    return EquipmentCoverage(
      status: (json['status'] ?? 'unknown').toString(),
      coveragePct: toInt(json['coverage_pct']),
      totalExercises: toInt(json['total_exercises']),
      requiredEquipment: toStrList(json['required_equipment']),
      missingEquipment: toStrList(json['missing_equipment']),
      swappableCount: toInt(json['swappable_count']),
      unswappableCount: toInt(json['unswappable_count']),
      fullyCoverable: json['fully_coverable'] == true,
      gymProfileId: json['gym_profile_id']?.toString(),
    );
  }
}
