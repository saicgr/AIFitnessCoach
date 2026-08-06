import 'dart:convert';

import '../../../core/constants/injury_options.dart';

/// One active-injury entry, robust to the two on-the-wire shapes that show up
/// in `users.active_injuries`:
///  - a canonical id string from onboarding (e.g. `'lower_back'`), or
///  - a structured object from the injury-recovery writer
///    (`{id, severity, body_part, reported_at, expected_recovery_date}`).
///
/// [User.injuriesList] (`data/models/user.dart`) calls `.toString()` on every
/// decoded element, so a structured entry arrives as an unreadable Dart-map
/// dump ("{id: 35759b11-…, severity: Moderate, body_part: …}") — this parser
/// reads `users.activeInjuries` (the raw JSON string) directly instead of
/// going through that getter, so it can pull a real label out of either shape.
class InjuryEntry {
  const InjuryEntry({required this.raw, required this.id, required this.label});

  /// The original decoded value (`String` or `Map`) — round-tripped back
  /// into `active_injuries` on removal so an unrelated edit never destroys
  /// a structured entry's severity/dates.
  final dynamic raw;

  /// Canonical id for string entries, or the structured entry's own `id`
  /// field (empty string if absent). Used only to key list operations.
  final String id;

  final String label;
}

/// Parse `users.activeInjuries` (raw JSON string) into display-ready entries.
/// Drops the `'none'` sentinel and any entry with no readable label.
List<InjuryEntry> parseActiveInjuries(String? rawJson) {
  if (rawJson == null || rawJson.isEmpty) return [];
  List<dynamic> decoded;
  try {
    final d = jsonDecode(rawJson);
    if (d is! List) return [];
    decoded = d;
  } catch (_) {
    return [];
  }

  final out = <InjuryEntry>[];
  for (final entry in decoded) {
    if (entry is String) {
      final id = normalizeInjuryId(entry);
      if (id.isEmpty || id == 'none') continue;
      out.add(InjuryEntry(raw: entry, id: id, label: injuryLabelFor(id)));
    } else if (entry is Map) {
      final bodyPart = entry['body_part'] ?? entry['bodyPart'];
      final label = _bodyPartLabel(bodyPart?.toString());
      if (label == null) continue;
      out.add(InjuryEntry(
        raw: entry,
        id: (entry['id'] ?? '').toString(),
        label: label,
      ));
    }
  }
  return out;
}

/// "quadriceps (quadriceps femoris), hamstrings (biceps femoris)" ->
/// "Quadriceps, Hamstrings" — drops the anatomical-name parenthetical and
/// title-cases each part so the chip reads like the rest of the app's labels.
String? _bodyPartLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parts = raw
      .split(',')
      .map((p) {
        final paren = p.indexOf('(');
        return (paren >= 0 ? p.substring(0, paren) : p).trim();
      })
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .toList();
  return parts.isEmpty ? null : parts.join(', ');
}
