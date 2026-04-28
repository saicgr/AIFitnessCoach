import 'package:flutter/widgets.dart';

/// What's being shared. Drives adapter selection and template availability.
enum ShareableKind {
  periodInsights,
  personalRecords,
  muscleAnalytics,
  oneRm,
  exerciseHistory,
  milestones,
  progressCharts,
  bodyMeasurements,
  nutrition,
  achievements,
  statsOverview,
  weeklyProgress,
  streak,
  workoutComplete,
  wrapped,
  insights,
  weeklySummary,
  strength,
  weeklyPlan,
  monthlyPlan,
}

extension ShareableKindMeta on ShareableKind {
  /// Hard floor for highlights — adapters that can't meet this MUST return null
  /// rather than build a half-populated payload (kills the white-bars bug).
  int get minHighlights {
    switch (this) {
      case ShareableKind.streak:
      case ShareableKind.milestones:
      case ShareableKind.achievements:
      case ShareableKind.workoutComplete:
      case ShareableKind.weeklyPlan:
      case ShareableKind.monthlyPlan:
        return 2;
      default:
        return 3;
    }
  }
}

/// Story (9:16), Portrait (4:5), Square (1:1) — drives capture size + layout.
enum ShareableAspect { story, portrait, square }

/// 5 preset color themes the user can pick from in the share sheet. Each is
/// applied as the accent color tint inside [ShareableCanvas] so the captured
/// PNG gets a distinct hue without per-template work.
enum ShareableTheme { charcoal, sand, indigo, forest, sunset }

extension ShareableThemeMeta on ShareableTheme {
  String get label {
    switch (this) {
      case ShareableTheme.charcoal:
        return 'Charcoal';
      case ShareableTheme.sand:
        return 'Sand';
      case ShareableTheme.indigo:
        return 'Indigo';
      case ShareableTheme.forest:
        return 'Forest';
      case ShareableTheme.sunset:
        return 'Sunset';
    }
  }

  Color get accent {
    switch (this) {
      case ShareableTheme.charcoal:
        return const Color(0xFF6B7280);
      case ShareableTheme.sand:
        return const Color(0xFFD4A373);
      case ShareableTheme.indigo:
        return const Color(0xFF6366F1);
      case ShareableTheme.forest:
        return const Color(0xFF16A34A);
      case ShareableTheme.sunset:
        return const Color(0xFFF97316);
    }
  }
}

extension ShareableAspectMeta on ShareableAspect {
  Size get size {
    switch (this) {
      case ShareableAspect.story:
        return const Size(1080, 1920);
      case ShareableAspect.portrait:
        return const Size(1080, 1350);
      case ShareableAspect.square:
        return const Size(1080, 1080);
    }
  }

  double get ratio => size.width / size.height;

  String get label {
    switch (this) {
      case ShareableAspect.square:
        return '1:1';
      case ShareableAspect.portrait:
        return '4:5';
      case ShareableAspect.story:
        return '9:16';
    }
  }
}

/// One label/value row inside a template (e.g. "TOTAL TIME" → "4h 32m").
@immutable
class ShareableMetric {
  final String label;
  final String value;
  final IconData? icon;
  final Color? accent;

  const ShareableMetric({
    required this.label,
    required this.value,
    this.icon,
    this.accent,
  });

  bool get isPopulated => label.trim().isNotEmpty && value.trim().isNotEmpty;
}

/// One logged set inside a workout share — Hevy-style WorkoutDetails template
/// renders these directly.
@immutable
class ShareableSet {
  final num? weight;
  final String unit; // 'lbs' or 'kg'
  final int reps;
  final num? rpe;

  /// Planned target weight for this set (from the workout plan). Used to
  /// render `135 × 10 (target 135 × 10)` in shares so viewers see what was
  /// supposed-to-do vs what was-done.
  final num? targetWeight;
  final int? targetReps;
  final int? targetRir;

  /// True when the exercise itself is bodyweight (so a null/0 weight should
  /// render as "BW" rather than "—"). Drives the share template's render
  /// branch and prevents mistakenly stamping "BW" on machine exercises that
  /// were just under-logged.
  final bool isBodyweight;

  const ShareableSet({
    this.weight,
    required this.unit,
    required this.reps,
    this.rpe,
    this.targetWeight,
    this.targetReps,
    this.targetRir,
    this.isBodyweight = false,
  });
}

@immutable
class ShareableExercise {
  final String name;
  final String? imageUrl;
  final List<ShareableSet> sets;

  const ShareableExercise({
    required this.name,
    this.imageUrl,
    this.sets = const [],
  });
}

/// One day of a multi-day plan share (week / month grid templates).
/// `date` is the scheduled day; null `workoutName` means rest day.
@immutable
class SharablePlanDay {
  final DateTime date;
  final String? workoutName;
  final String? workoutType; // 'strength' | 'cardio' | 'hiit' | ...
  final List<ShareableExercise> exercises;
  final bool isCompleted;
  final int? durationMinutes;

  const SharablePlanDay({
    required this.date,
    this.workoutName,
    this.workoutType,
    this.exercises = const [],
    this.isCompleted = false,
    this.durationMinutes,
  });

  bool get isRestDay => workoutName == null || workoutName!.trim().isEmpty;
}

/// Unified payload for every share surface. Every existing share-data DTO
/// (`ReportShareData`, `StatsSnapshot`, the bag of fields on `ShareWorkoutSheet`)
/// gets adapted to this shape via the adapters in `lib/shareables/adapters/`.
///
/// Validation contract: an adapter MUST return either a fully-populated
/// `Shareable` (≥`kind.minHighlights` real highlights) or `null`. Templates
/// never paper over missing data with `--` placeholders — they decline to
/// render via the catalog availability check.
@immutable
class Shareable {
  final ShareableKind kind;
  final String title;
  final String periodLabel;
  final num? heroValue;
  final String heroUnitSingular;
  final String? heroPrefix;
  final String? heroSuffix;
  final List<ShareableMetric> highlights;
  final List<ShareableMetric> subMetrics;
  final List<ShareableExercise>? exercises;
  final List<SharablePlanDay>? planDays;
  final Map<String, int>? musclesWorked;
  final String? userDisplayName;
  final String? userAvatarUrl;
  /// Optional headline image — typically the most-emphasized exercise's
  /// illustration / gif. Polaroid, Magazine Cover, and Exercise Showcase
  /// templates render this as their visual centerpiece. Null falls back
  /// to gradient fills.
  final String? heroImageUrl;

  /// User-uploaded photo path (image_picker output, local file path).
  /// Photo-category templates render this full-bleed under a darkening
  /// scrim. Null means the templates fall back to a gradient backdrop
  /// using [accentColor].
  final String? customPhotoPath;

  /// Second user-uploaded photo path used by the before/after template.
  final String? customPhotoPathSecondary;

  final Color accentColor;
  final String? deepLinkUrl;
  final ShareableAspect aspect;
  /// Optional user-typed caption rendered above the captured card. Templates
  /// that don't display captions ignore it. Max 80 chars enforced by the UI.
  final String? caption;

  Shareable({
    required this.kind,
    required this.title,
    required this.periodLabel,
    required this.accentColor,
    this.heroValue,
    this.heroUnitSingular = '',
    this.heroPrefix,
    this.heroSuffix,
    this.highlights = const [],
    this.subMetrics = const [],
    this.exercises,
    this.planDays,
    this.musclesWorked,
    this.userDisplayName,
    this.userAvatarUrl,
    this.heroImageUrl,
    this.customPhotoPath,
    this.customPhotoPathSecondary,
    this.deepLinkUrl,
    this.aspect = ShareableAspect.story,
    this.caption,
  }) {
    assert(() {
      // Debug-only: surface impoverished payloads at construction time, not
      // at render time when they show up as visible empty bars.
      final populated = highlights.where((h) => h.isPopulated).length;
      if (populated < kind.minHighlights) {
        debugPrint(
          '⚠️ Shareable($kind) constructed with $populated populated highlights, '
          'expected ≥${kind.minHighlights}. Adapter should have returned null.',
        );
      }
      return true;
    }());
  }

  Shareable copyWith({
    ShareableAspect? aspect,
    Color? accentColor,
    String? deepLinkUrl,
    String? customPhotoPath,
    String? customPhotoPathSecondary,
    bool clearCustomPhoto = false,
    bool clearCustomPhotoSecondary = false,
    String? caption,
    bool clearCaption = false,
  }) {
    return Shareable(
      kind: kind,
      title: title,
      periodLabel: periodLabel,
      heroValue: heroValue,
      heroUnitSingular: heroUnitSingular,
      heroPrefix: heroPrefix,
      heroSuffix: heroSuffix,
      highlights: highlights,
      subMetrics: subMetrics,
      exercises: exercises,
      planDays: planDays,
      musclesWorked: musclesWorked,
      userDisplayName: userDisplayName,
      userAvatarUrl: userAvatarUrl,
      heroImageUrl: heroImageUrl,
      customPhotoPath: clearCustomPhoto
          ? null
          : (customPhotoPath ?? this.customPhotoPath),
      customPhotoPathSecondary: clearCustomPhotoSecondary
          ? null
          : (customPhotoPathSecondary ?? this.customPhotoPathSecondary),
      accentColor: accentColor ?? this.accentColor,
      deepLinkUrl: deepLinkUrl ?? this.deepLinkUrl,
      aspect: aspect ?? this.aspect,
      caption: clearCaption ? null : (caption ?? this.caption),
    );
  }
}

/// Pluralization helper — `Plural.of(1, 'workout') == 'workout'`,
/// `Plural.of(7, 'workout') == 'workouts'`. Handles common irregulars
/// in the fitness vocabulary (PR/PRs, lift/lifts, kcal/kcal).
class Plural {
  static const _invariants = {'kcal', 'kg', 'lbs', 'lb', 'reps'};
  static const _customPlurals = {
    'PR': 'PRs',
    'pr': 'prs',
    '1RM': '1RMs',
  };

  static String of(num? n, String singular) {
    if (n == null) return singular;
    if (n == 1) return singular;
    if (_invariants.contains(singular)) return singular;
    final custom = _customPlurals[singular];
    if (custom != null) return custom;
    if (singular.endsWith('s')) return singular;
    return '${singular}s';
  }
}

/// Returns the full hero string with prefix, formatted value, and suffix.
/// Unit is rendered separately by templates so Plural can apply correctly.
String shareableHeroString(Shareable s) {
  if (s.heroValue == null) return '—';
  final v = s.heroValue!;
  String formatted;
  if (v is int) {
    formatted = v.toString();
  } else if (v == v.roundToDouble()) {
    formatted = v.round().toString();
  } else {
    formatted = v.toStringAsFixed(1);
  }
  return '${s.heroPrefix ?? ''}$formatted${s.heroSuffix ?? ''}';
}

/// Pluralized unit label for the hero value (e.g. "1 workout" vs "7 workouts").
/// Templates render `${shareableHeroString(s)} ${shareableHeroUnit(s)}`.
String shareableHeroUnit(Shareable s) {
  if (s.heroUnitSingular.isEmpty) return '';
  return Plural.of(s.heroValue, s.heroUnitSingular);
}
