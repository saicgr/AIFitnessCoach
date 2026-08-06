import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/profile/widgets/injury_entry_parser.dart';

void main() {
  group('parseActiveInjuries', () {
    test('drops the none sentinel and labels a canonical id string', () {
      final entries = parseActiveInjuries('["none", "lower_back"]');
      expect(entries, hasLength(1));
      expect(entries.single.label, 'Lower Back');
    });

    test(
        'extracts a real body-part label from a structured injury-recovery '
        'entry instead of the raw map dump the bug produced', () {
      // Regression for the row-10 CRIT: users.active_injuries can hold a
      // heterogeneous array — a legacy string sentinel plus a structured
      // object written by the injury-recovery pipeline. Before the fix, this
      // shape reached the UI as `{id: 35759b11-…, Sev…` (User.injuriesList's
      // `.toString()` on the Map) and blew the profile card's layout apart.
      const raw = '''
      [
        "none",
        {
          "id": "35759b11-901d-402c-bada-f1179a411cf5",
          "severity": "moderate",
          "body_part": "quadriceps (quadriceps femoris), hamstrings (biceps femoris)",
          "reported_at": "2026-08-05T06:01:04",
          "expected_recovery_date": "2026-08-26T06:01:04"
        }
      ]
      ''';

      final entries = parseActiveInjuries(raw);

      expect(entries, hasLength(1));
      final label = entries.single.label;
      // The defect under test: the label must be a real, short body-part
      // name — never the raw map dump (which contains "id:", "Sev...", or
      // the uuid) and never long enough to blow out a fixed-width chip.
      expect(label, 'Quadriceps, Hamstrings');
      expect(label, isNot(contains('id:')));
      expect(label, isNot(contains('35759b11')));
      expect(label.length, lessThan(60));
      expect(entries.single.raw, isA<Map>());
    });

    test('mixed list: string + structured entries both round-trip via raw',
        () {
      const raw = '''
      [
        "lower_back",
        {"id": "abc123", "body_part": "shoulder"}
      ]
      ''';
      final entries = parseActiveInjuries(raw);
      expect(entries, hasLength(2));
      expect(entries[0].raw, 'lower_back');
      expect(entries[0].label, 'Lower Back');
      expect(entries[1].raw, isA<Map>());
      expect(entries[1].label, 'Shoulder');
    });

    test('null/empty/malformed input yields no entries', () {
      expect(parseActiveInjuries(null), isEmpty);
      expect(parseActiveInjuries(''), isEmpty);
      expect(parseActiveInjuries('not json'), isEmpty);
      expect(parseActiveInjuries('{"not":"a list"}'), isEmpty);
    });
  });
}
