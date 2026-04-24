import 'package:flutter/material.dart';

/// Granular activity kind for synced (Health Connect / Apple Health) workouts.
///
/// Distinct from `Workout.type` — the legacy workout type field (`cardio`,
/// `strength`, `flexibility`, `hiit`) is coupled to achievements, the home
/// hero card, the schedule week selector, and many other UI paths, so we do
/// not repurpose it. Instead, synced imports store their granular kind in
/// `generation_metadata.hc_activity_kind`, read by synced-workout UI only.
enum SyncedKind {
  walking,
  running,
  cycling,
  swimming,
  rowing,
  hiking,
  elliptical,
  stairs,
  skating,
  dance,
  yoga,
  pilates,
  hiit,
  tennis,
  basketball,
  football,
  soccer,
  strength,
  other;

  static SyncedKind fromString(String? raw) {
    if (raw == null || raw.isEmpty) return SyncedKind.other;
    final s = raw.toLowerCase().trim();
    for (final k in SyncedKind.values) {
      if (k.name == s) return k;
    }
    // Tolerant aliases
    switch (s) {
      case 'walk':
        return SyncedKind.walking;
      case 'run':
        return SyncedKind.running;
      case 'bike':
      case 'biking':
      case 'bicycling':
        return SyncedKind.cycling;
      case 'swim':
        return SyncedKind.swimming;
      case 'row':
        return SyncedKind.rowing;
      case 'hike':
        return SyncedKind.hiking;
      case 'elliptical_trainer':
        return SyncedKind.elliptical;
      case 'stair':
      case 'stair_climbing':
        return SyncedKind.stairs;
      case 'weightlifting':
      case 'resistance':
      case 'strength_training':
        return SyncedKind.strength;
      case 'high_intensity_interval_training':
        return SyncedKind.hiit;
      case 'cardio':
        return SyncedKind.other;
      default:
        return SyncedKind.other;
    }
  }

  String get label {
    switch (this) {
      case SyncedKind.walking:
        return 'Walking';
      case SyncedKind.running:
        return 'Running';
      case SyncedKind.cycling:
        return 'Cycling';
      case SyncedKind.swimming:
        return 'Swimming';
      case SyncedKind.rowing:
        return 'Rowing';
      case SyncedKind.hiking:
        return 'Hiking';
      case SyncedKind.elliptical:
        return 'Elliptical';
      case SyncedKind.stairs:
        return 'Stair Climb';
      case SyncedKind.skating:
        return 'Skating';
      case SyncedKind.dance:
        return 'Dance';
      case SyncedKind.yoga:
        return 'Yoga';
      case SyncedKind.pilates:
        return 'Pilates';
      case SyncedKind.hiit:
        return 'HIIT';
      case SyncedKind.tennis:
        return 'Tennis';
      case SyncedKind.basketball:
        return 'Basketball';
      case SyncedKind.football:
        return 'Football';
      case SyncedKind.soccer:
        return 'Soccer';
      case SyncedKind.strength:
        return 'Strength';
      case SyncedKind.other:
        return 'Workout';
    }
  }

  IconData get icon {
    switch (this) {
      case SyncedKind.walking:
        return Icons.directions_walk_rounded;
      case SyncedKind.running:
        return Icons.directions_run_rounded;
      case SyncedKind.cycling:
        return Icons.directions_bike_rounded;
      case SyncedKind.swimming:
        return Icons.pool_rounded;
      case SyncedKind.rowing:
        return Icons.rowing_rounded;
      case SyncedKind.hiking:
        return Icons.terrain_rounded;
      case SyncedKind.elliptical:
        return Icons.auto_awesome_motion_rounded;
      case SyncedKind.stairs:
        return Icons.stairs_rounded;
      case SyncedKind.skating:
        return Icons.ice_skating_rounded;
      case SyncedKind.dance:
        return Icons.music_note_rounded;
      case SyncedKind.yoga:
        return Icons.self_improvement_rounded;
      case SyncedKind.pilates:
        return Icons.accessibility_new_rounded;
      case SyncedKind.hiit:
        return Icons.local_fire_department_rounded;
      case SyncedKind.tennis:
        return Icons.sports_tennis_rounded;
      case SyncedKind.basketball:
        return Icons.sports_basketball_rounded;
      case SyncedKind.football:
        return Icons.sports_football_rounded;
      case SyncedKind.soccer:
        return Icons.sports_soccer_rounded;
      case SyncedKind.strength:
        return Icons.fitness_center_rounded;
      case SyncedKind.other:
        return Icons.sync_rounded;
    }
  }

  KindPalette palette(bool isDark) {
    switch (this) {
      case SyncedKind.walking:
        return const KindPalette(
          fg: Color(0xFF22C55E),
          bgDark: Color(0x262ECC71),
          bgLight: Color(0xFFDCFCE7),
        );
      case SyncedKind.running:
        return const KindPalette(
          fg: Color(0xFFF97316),
          bgDark: Color(0x26F97316),
          bgLight: Color(0xFFFFEDD5),
        );
      case SyncedKind.cycling:
        return const KindPalette(
          fg: Color(0xFF0EA5E9),
          bgDark: Color(0x260EA5E9),
          bgLight: Color(0xFFE0F2FE),
        );
      case SyncedKind.swimming:
        return const KindPalette(
          fg: Color(0xFF2563EB),
          bgDark: Color(0x262563EB),
          bgLight: Color(0xFFDBEAFE),
        );
      case SyncedKind.rowing:
        return const KindPalette(
          fg: Color(0xFF14B8A6),
          bgDark: Color(0x2614B8A6),
          bgLight: Color(0xFFCCFBF1),
        );
      case SyncedKind.hiking:
        return const KindPalette(
          fg: Color(0xFF84CC16),
          bgDark: Color(0x2684CC16),
          bgLight: Color(0xFFECFCCB),
        );
      case SyncedKind.elliptical:
        return const KindPalette(
          fg: Color(0xFF06B6D4),
          bgDark: Color(0x2606B6D4),
          bgLight: Color(0xFFCFFAFE),
        );
      case SyncedKind.stairs:
        return const KindPalette(
          fg: Color(0xFF8B5CF6),
          bgDark: Color(0x268B5CF6),
          bgLight: Color(0xFFEDE9FE),
        );
      case SyncedKind.skating:
        return const KindPalette(
          fg: Color(0xFF3B82F6),
          bgDark: Color(0x263B82F6),
          bgLight: Color(0xFFDBEAFE),
        );
      case SyncedKind.dance:
        return const KindPalette(
          fg: Color(0xFFEC4899),
          bgDark: Color(0x26EC4899),
          bgLight: Color(0xFFFCE7F3),
        );
      case SyncedKind.yoga:
        return const KindPalette(
          fg: Color(0xFFA855F7),
          bgDark: Color(0x26A855F7),
          bgLight: Color(0xFFF3E8FF),
        );
      case SyncedKind.pilates:
        return const KindPalette(
          fg: Color(0xFFF472B6),
          bgDark: Color(0x26F472B6),
          bgLight: Color(0xFFFCE7F3),
        );
      case SyncedKind.hiit:
        return const KindPalette(
          fg: Color(0xFFE11D48),
          bgDark: Color(0x26E11D48),
          bgLight: Color(0xFFFFE4E6),
        );
      case SyncedKind.tennis:
        return const KindPalette(
          fg: Color(0xFFEAB308),
          bgDark: Color(0x26EAB308),
          bgLight: Color(0xFFFEF9C3),
        );
      case SyncedKind.basketball:
        return const KindPalette(
          fg: Color(0xFFEA580C),
          bgDark: Color(0x26EA580C),
          bgLight: Color(0xFFFFEDD5),
        );
      case SyncedKind.football:
        return const KindPalette(
          fg: Color(0xFF7C3AED),
          bgDark: Color(0x267C3AED),
          bgLight: Color(0xFFEDE9FE),
        );
      case SyncedKind.soccer:
        return const KindPalette(
          fg: Color(0xFF15803D),
          bgDark: Color(0x2615803D),
          bgLight: Color(0xFFDCFCE7),
        );
      case SyncedKind.strength:
        return const KindPalette(
          fg: Color(0xFFEF4444),
          bgDark: Color(0x26EF4444),
          bgLight: Color(0xFFFEE2E2),
        );
      case SyncedKind.other:
        return const KindPalette(
          fg: Color(0xFF64748B),
          bgDark: Color(0x2664748B),
          bgLight: Color(0xFFF1F5F9),
        );
    }
  }

  /// Ordered metric keys to feature for this kind's hero banner + card chips.
  /// Keys reference `generation_metadata` fields; `duration` means the
  /// workout-level durationMinutes.
  List<String> get heroMetricOrder {
    switch (this) {
      case SyncedKind.walking:
      case SyncedKind.running:
      case SyncedKind.hiking:
        return const [
          'distance_m',
          'pace_sec_per_km',
          'calories_active',
          'steps',
        ];
      case SyncedKind.cycling:
        return const [
          'distance_m',
          'avg_speed_mps',
          'calories_active',
          'elevation_gain_m',
        ];
      case SyncedKind.swimming:
      case SyncedKind.rowing:
        return const [
          'distance_m',
          'duration',
          'calories_active',
          'avg_heart_rate',
        ];
      case SyncedKind.strength:
        return const [
          'duration',
          'calories_active',
          'avg_heart_rate',
          'max_heart_rate',
        ];
      case SyncedKind.yoga:
      case SyncedKind.pilates:
        return const [
          'duration',
          'calories_active',
          'avg_heart_rate',
          'avg_respiratory_rate',
        ];
      case SyncedKind.hiit:
        return const [
          'duration',
          'calories_active',
          'max_heart_rate',
          'avg_heart_rate',
        ];
      case SyncedKind.elliptical:
      case SyncedKind.stairs:
      case SyncedKind.skating:
      case SyncedKind.dance:
      case SyncedKind.tennis:
      case SyncedKind.basketball:
      case SyncedKind.football:
      case SyncedKind.soccer:
      case SyncedKind.other:
        return const [
          'duration',
          'calories_active',
          'distance_m',
          'avg_heart_rate',
        ];
    }
  }
}

/// Color triplet used by a [SyncedKind]:
///  * [fg]      — solid foreground (icon fill, chart line, hero gradient seed)
///  * [bgDark]  — tint applied over OLED black (≈15% alpha)
///  * [bgLight] — named pastel for light-mode surfaces (≈100% opacity)
class KindPalette {
  final Color fg;
  final Color bgDark;
  final Color bgLight;

  const KindPalette({
    required this.fg,
    required this.bgDark,
    required this.bgLight,
  });

  Color bg(bool isDark) => isDark ? bgDark : bgLight;
}
