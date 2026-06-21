/// Canonical injury / limitation options — the SINGLE source of truth shared by
/// onboarding, the profile fitness card, and the workout-screen limitations
/// sheet. Mirrors the backend's expected ids (knees/shoulders/lower_back/…) so
/// the safety index + avoided-muscle mapping actually match.
///
/// IMPORTANT (injury-2026-06): the profile card historically stored Title-Case
/// LABELS ('Lower Back', 'Shoulder'), but the backend resolver matches canonical
/// ids ('lower_back' in 'lower back' → false because of the underscore). That
/// meant profile-edited injuries were silently ignored by generation safety.
/// Always store the ID from [kInjuryOptions]; render the label via
/// [injuryLabelFor]; normalize any legacy/freeform value via [normalizeInjuryId].
library;

/// (id, label) — the 19 body-part chips. Excludes the onboarding-only sentinels
/// 'none' (empty selection == none) and 'other' (free-text, handled separately).
const List<(String, String)> kInjuryOptions = [
  ('neck', 'Neck'),
  ('shoulders', 'Shoulders'),
  ('upper_back', 'Upper Back'),
  ('chest', 'Chest'),
  ('biceps', 'Biceps'),
  ('triceps', 'Triceps'),
  ('elbows', 'Elbows'),
  ('forearms', 'Forearms'),
  ('wrists', 'Wrists'),
  ('abs', 'Abs'),
  ('lower_back', 'Lower Back'),
  ('hips', 'Hips'),
  ('glutes', 'Glutes'),
  ('groin', 'Groin'),
  ('quads', 'Quads'),
  ('hamstrings', 'Hamstrings'),
  ('knees', 'Knees'),
  ('calves', 'Calves'),
  ('ankles', 'Ankles'),
];

/// Legacy Title-Case / singular labels the old 8-chip profile card stored,
/// mapped to the canonical id so existing user data normalizes correctly.
const Map<String, String> _kInjuryLegacyAliases = {
  'lower back': 'lower_back',
  'upper back': 'upper_back',
  'shoulder': 'shoulders',
  'knee': 'knees',
  'wrist': 'wrists',
  'ankle': 'ankles',
  'hip': 'hips',
  'elbow': 'elbows',
  'bicep': 'biceps',
  'tricep': 'triceps',
  'quad': 'quads',
  'hamstring': 'hamstrings',
  'calf': 'calves',
};

final Map<String, String> _kIdToLabel = {
  for (final (id, label) in kInjuryOptions) id: label,
};

/// Human label for an injury id (falls back to a Title-Cased version of any
/// custom/unknown id so free-text 'other' injuries still render readably).
String injuryLabelFor(String id) {
  final canonical = normalizeInjuryId(id);
  final known = _kIdToLabel[canonical];
  if (known != null) return known;
  // Title-case a freeform/unknown value: 'carpal_tunnel' -> 'Carpal Tunnel'.
  return canonical
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Normalize a stored/freeform injury value to its canonical id. Handles legacy
/// Title-Case labels, singular forms, and spaces→underscores. Unknown values are
/// lowercased + underscored (preserved, never dropped — e.g. custom 'other').
String normalizeInjuryId(String raw) {
  final lower = raw.trim().toLowerCase();
  if (lower.isEmpty) return lower;
  if (_kIdToLabel.containsKey(lower)) return lower; // already canonical
  final alias = _kInjuryLegacyAliases[lower];
  if (alias != null) return alias;
  final underscored = lower.replaceAll(RegExp(r'\s+'), '_');
  if (_kIdToLabel.containsKey(underscored)) return underscored;
  return _kInjuryLegacyAliases[lower.replaceAll('_', ' ')] ?? underscored;
}

/// Normalize + dedupe a stored injury list (drops 'none'/empty sentinels).
List<String> normalizeInjuryList(Iterable<String> raw) {
  final out = <String>[];
  for (final r in raw) {
    final id = normalizeInjuryId(r);
    if (id.isEmpty || id == 'none') continue;
    if (!out.contains(id)) out.add(id);
  }
  return out;
}
