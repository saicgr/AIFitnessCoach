/// Canonical muscle alias map + body-atlas ID resolver.
///
/// This is the single source of truth for normalizing free-form muscle
/// names (from Gemini-generated workouts, Supabase `exercise_library`
/// rows, custom user exercises, etc.) into a small set of display
/// buckets used by the post-workout summary screen.
///
/// Two consumers:
/// 1. `WorkoutSummaryGeneral._MusclesWorkedSection` — renders one chip
///    per canonical bucket with a set count.
/// 2. `WorkoutSummaryAdvanced._MuscleHeatmap` — colors anatomical
///    regions on the `flutter_body_atlas` SVG. Each canonical bucket
///    expands to one or more atlas IDs (e.g. `Core` → all rectus
///    abdominis + oblique segments) so the silhouette visibly lights
///    up instead of showing a single hairline-thin slice.
///
/// Edge cases (per plan §73-83):
/// - Cardio exercises bucket to `Cardio` (no atlas mapping; UI shows
///   duration chip only).
/// - Stretches still surface in the chip list under their normal
///   muscle bucket, but the caller can choose to render them with a
///   muted color and a separate header.
/// - Truly unknown labels (NULL primary_muscle, no muscle_group)
///   bucket to `Other` and render with a neutral chip.
library;

/// Map of lowercased free-form muscle name → canonical bucket. Keys
/// MUST be lowercase trimmed. Values are display-cased.
///
/// Categories:
///   Core / Back / Chest / Shoulders / Quads / Hamstrings / Glutes /
///   Calves / Biceps / Triceps / Forearms / Lower Back / Hips /
///   Adductors / Cardio
const Map<String, String> muscleAliases = {
  // ── Core ─────────────────────────────────────────────────────────
  'abs': 'Core',
  'abdominals': 'Core',
  'core': 'Core',
  'rectus abdominis': 'Core',
  'transverse abdominis': 'Core',
  'transversus abdominis': 'Core',
  'obliques': 'Core',
  'external obliques': 'Core',
  'internal obliques': 'Core',
  'lower abs': 'Core',
  'upper abs': 'Core',
  'six pack': 'Core',
  'midsection': 'Core',
  'waist': 'Core', // Supabase exercise_library uses body_part='waist' for all 131 ab/plank rows
  'serratus anterior': 'Core',

  // ── Back (lats + mid back collapse here; sub-muscles preserved
  //   through atlas ID expansion in `bodyAtlasIdsFor`) ─────────────
  'back': 'Back',
  'lats': 'Back',
  'latissimus dorsi': 'Back',
  'middle back': 'Back',
  'upper back': 'Back',
  'rhomboids': 'Back',
  'rhomboid major': 'Back',
  'rhomboid minor': 'Back',
  'traps': 'Back',
  'trapezius': 'Back',
  'teres major': 'Back',
  'teres minor': 'Back',
  'infraspinatus': 'Back',
  'erector spinae': 'Back',

  // ── Lower Back ──────────────────────────────────────────────────
  'lower back': 'Lower Back',
  'lumbar': 'Lower Back',
  'spinal erectors': 'Lower Back',

  // ── Chest ───────────────────────────────────────────────────────
  'chest': 'Chest',
  'pecs': 'Chest',
  'pectorals': 'Chest',
  'pectoralis major': 'Chest',
  'pectoralis minor': 'Chest',
  'upper chest': 'Chest',
  'lower chest': 'Chest',
  'inner chest': 'Chest',

  // ── Shoulders ───────────────────────────────────────────────────
  'shoulders': 'Shoulders',
  'shoulder': 'Shoulders',
  'delts': 'Shoulders',
  'deltoids': 'Shoulders',
  'deltoid': 'Shoulders',
  'front delts': 'Shoulders',
  'front deltoid': 'Shoulders',
  'anterior deltoid': 'Shoulders',
  'rear delts': 'Shoulders',
  'rear deltoid': 'Shoulders',
  'posterior deltoid': 'Shoulders',
  'side delts': 'Shoulders',
  'lateral deltoid': 'Shoulders',
  'medial deltoid': 'Shoulders',

  // ── Quads ───────────────────────────────────────────────────────
  'quads': 'Quads',
  'quadriceps': 'Quads',
  'rectus femoris': 'Quads',
  'vastus lateralis': 'Quads',
  'vastus medialis': 'Quads',
  'vastus intermedius': 'Quads',
  'vastus': 'Quads',

  // ── Hamstrings ──────────────────────────────────────────────────
  'hams': 'Hamstrings',
  'hamstrings': 'Hamstrings',
  'hamstring': 'Hamstrings',
  'biceps femoris': 'Hamstrings',
  'semitendinosus': 'Hamstrings',
  'semimembranosus': 'Hamstrings',

  // ── Glutes ──────────────────────────────────────────────────────
  'glutes': 'Glutes',
  'glute': 'Glutes',
  'gluteus': 'Glutes',
  'gluteus maximus': 'Glutes',
  'gluteus medius': 'Glutes',
  'gluteus minimus': 'Glutes',
  'glute max': 'Glutes',
  'glute med': 'Glutes',

  // ── Calves ──────────────────────────────────────────────────────
  'calves': 'Calves',
  'calf': 'Calves',
  'gastrocnemius': 'Calves',
  'soleus': 'Calves',

  // ── Biceps ──────────────────────────────────────────────────────
  'biceps': 'Biceps',
  'bicep': 'Biceps',
  'biceps brachii': 'Biceps',
  'brachialis': 'Biceps',
  'brachioradialis': 'Biceps',

  // ── Triceps ─────────────────────────────────────────────────────
  'triceps': 'Triceps',
  'tricep': 'Triceps',
  'triceps brachii': 'Triceps',

  // ── Forearms ────────────────────────────────────────────────────
  'forearms': 'Forearms',
  'forearm': 'Forearms',
  'wrist flexors': 'Forearms',
  'wrist extensors': 'Forearms',

  // ── Hips / Adductors ────────────────────────────────────────────
  'hips': 'Hips',
  'hip flexors': 'Hips',
  'hip flexor': 'Hips',
  'iliopsoas': 'Hips',
  'psoas': 'Hips',
  'adductors': 'Adductors',
  'adductor': 'Adductors',
  'inner thigh': 'Adductors',
  'inner thighs': 'Adductors',
  'adductor magnus': 'Adductors',
  'adductor longus': 'Adductors',
  'adductor brevis': 'Adductors',
  'pectineus': 'Adductors',
  'gracilis': 'Adductors',

  // ── Cardio (no atlas mapping; UI shows duration chip) ───────────
  'cardio': 'Cardio',
  'cardiovascular': 'Cardio',
  'aerobic': 'Cardio',
  'full body': 'Full Body',
  'full_body': 'Full Body',

  // ── ExerciseDB body_part values used in Supabase exercise_library
  //   (these come through as fallback when target_muscle is missing). ──
  'upper arms': 'Arms',
  'lower arms': 'Forearms',
  'upper legs': 'Legs',
  'lower legs': 'Calves',
  'neck': 'Neck',
};

/// Lowercase + trim + map to canonical bucket. Falls back to
/// title-cased input when the alias is unknown — callers that want a
/// strict "Other" bucket can compare the result to the input.
String canonicalMuscle(String raw) {
  final stripped = raw.trim().replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');
  if (stripped.isEmpty) return 'Other';
  final lower = stripped.toLowerCase();
  final hit = muscleAliases[lower];
  if (hit != null) return hit;
  // Try removing trailing 's' (plural normalization) for one more
  // chance — e.g. "tricep" already covered, but catches edge cases.
  if (lower.endsWith('s')) {
    final singular = lower.substring(0, lower.length - 1);
    final hitSingular = muscleAliases[singular];
    if (hitSingular != null) return hitSingular;
  }
  return _titleCase(stripped);
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s
      .split(' ')
      .map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      })
      .join(' ');
}

/// Returns the list of `flutter_body_atlas` muscle IDs (from
/// `Muscle.id` in package `flutter_body_atlas`) that correspond to a
/// given canonical bucket. Used to paint multi-segment muscles
/// (rectus abdominis is split into 7 segments in the SVG; lats are
/// 2 sides; etc.) as one cohesive region.
///
/// Returns `<String>[]` for buckets with no anatomical mapping
/// (Cardio, Other, Full Body).
///
/// Atlas IDs verified against
/// `flutter_body_atlas-0.1.4/lib/src/models/muscle.dart`.
List<String> bodyAtlasIdsFor(String canonical) {
  switch (canonical) {
    case 'Core':
      return const [
        // Rectus abdominis (the visible "six pack")
        'rectus_abdominis_1',
        'rectus_abdominis_2_l', 'rectus_abdominis_2_r',
        'rectus_abdominis_3_l', 'rectus_abdominis_3_r',
        'rectus_abdominis_4_l', 'rectus_abdominis_4_r',
        // External obliques (8 segments per side in this atlas)
        'external_oblique_l', 'external_oblique_r',
        'external_oblique_1_l', 'external_oblique_1_r',
        'external_oblique_2_l', 'external_oblique_2_r',
        'external_oblique_3_l', 'external_oblique_3_r',
        'external_oblique_4_l', 'external_oblique_4_r',
        'external_oblique_5_l', 'external_oblique_5_r',
        'external_oblique_6_l', 'external_oblique_6_r',
        'external_oblique_7_l', 'external_oblique_7_r',
        'external_oblique_8_l', 'external_oblique_8_r',
      ];
    case 'Back':
      return const [
        'latissimus_dorsi_l', 'latissimus_dorsi_r',
        'infraspinatus_l', 'infraspinatus_r',
        'trapezius_middle_l', 'trapezius_middle_r',
        'trapezius_lower_l', 'trapezius_lower_r',
        'trapezius_upper_l', 'trapezius_upper_r',
      ];
    case 'Lower Back':
      // Atlas has no dedicated lumbar; lower trap approximates.
      return const [
        'trapezius_lower_l',
        'trapezius_lower_r',
      ];
    case 'Chest':
      return const ['pectoralis_major_l', 'pectoralis_major_r'];
    case 'Shoulders':
      return const [
        'anterior_deltoid_l', 'anterior_deltoid_r',
        'lateral_deltoid_l', 'lateral_deltoid_r',
        'posterior_deltoid_l', 'posterior_deltoid_r',
      ];
    case 'Quads':
      return const [
        'rectus_femoris_l', 'rectus_femoris_r',
        'vastus_lateralis_l', 'vastus_lateralis_r',
        'vastus_medialis_l', 'vastus_medialis_r',
        'sartoris_l', 'sartoris_r',
      ];
    case 'Hamstrings':
      return const [
        'biceps_femoris_l', 'biceps_femoris_r',
        'semitendinosus_l', 'semitendinosus_r',
        'semimembranosus_1_l', 'semimembranosus_1_r',
        'semimembranosus_2_l', 'semimembranosus_2_r',
      ];
    case 'Glutes':
      return const [
        'gluteus_maximus_l', 'gluteus_maximus_r',
        'gluteus_medius_1_l', 'gluteus_medius_1_r',
        'gluteus_medius_2_l', 'gluteus_medius_2_r',
      ];
    case 'Calves':
      return const ['gastrocnemius_l', 'gastrocnemius_r'];
    case 'Biceps':
      return const [
        'biceps_brachii_caput_breve_l', 'biceps_brachii_caput_breve_r',
        'biceps_brachii_caput_longum_l', 'biceps_brachii_caput_longum_r',
        'brachioradialis_l', 'brachioradialis_r',
      ];
    case 'Triceps':
      return const [
        'triceps_brachii_caput_laterale_l', 'triceps_brachii_caput_laterale_r',
        'triceps_brachii_caput_longum_l', 'triceps_brachii_caput_longum_r',
        'triceps_brachii_caput_mediale_l', 'triceps_brachii_caput_mediale_r',
      ];
    case 'Forearms':
      return const [
        'extensor_digitorum_l', 'extensor_digitorum_r',
        'extensor_carpi_ulnaris_l', 'extensor_carpi_ulnaris_r',
        'flexor_carpi_ulnaris_l', 'flexor_carpi_ulnaris_r',
        'flexor_carpi_radialis_l', 'flexor_carpi_radialis_r',
        'extensor_carpi_radialis_longus_l', 'extensor_carpi_radialis_longus_r',
        'flexor_digitorum_superficialis_l', 'flexor_digitorum_superficialis_r',
        'pronator_teres_l', 'pronator_teres_r',
      ];
    case 'Adductors':
      return const [
        'adductor_magnus_l', 'adductor_magnus_r',
        'adductor_longus_l', 'adductor_longus_r',
        'pectineus_l', 'pectineus_r',
        'gracilis_l', 'gracilis_r',
      ];
    case 'Hips':
      // Hip flexors aren't surfaced in the atlas; sartorius is the
      // closest visible proxy for the anterior hip line.
      return const ['sartoris_l', 'sartoris_r'];
    case 'Cardio':
    case 'Full Body':
    case 'Other':
    default:
      return const [];
  }
}

/// Returns true if the canonical bucket is rendered on the FRONT
/// view of the body atlas. Used by the Front/Back toggle to decide
/// which view defaults to highlighted.
bool isFrontMuscle(String canonical) {
  switch (canonical) {
    case 'Core':
    case 'Chest':
    case 'Quads':
    case 'Biceps':
    case 'Adductors':
    case 'Hips':
    case 'Forearms':
      return true;
    default:
      return false;
  }
}

/// True if a muscle has BACK-view atlas IDs (lats, hams, glutes,
/// calves, traps, triceps, etc.). Some buckets — like Shoulders —
/// straddle both views.
bool isBackMuscle(String canonical) {
  switch (canonical) {
    case 'Back':
    case 'Lower Back':
    case 'Hamstrings':
    case 'Glutes':
    case 'Calves':
    case 'Triceps':
      return true;
    case 'Shoulders':
      // Anterior + posterior deltoids both — render in both views.
      return true;
    default:
      return false;
  }
}
