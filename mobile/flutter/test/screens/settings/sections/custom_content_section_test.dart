import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/settings/sections/custom_content_section.dart';

// REGRESSION (E2E settings row 20): users.custom_equipment is stored as a
// JSON-encoded string. It must go through jsonDecode — a raw comma-split
// previously turned the empty-array string '[]' into a phantom one-item
// list containing the literal text "[]", which then rendered as a fake
// equipment entry with a delete button instead of the empty state.
void main() {
  group('parseCustomEquipment', () {
    test('empty-array JSON string parses to an empty list (not ["[]"])', () {
      final result = parseCustomEquipment('[]');
      expect(result, isEmpty);
    });

    test('null parses to an empty list', () {
      expect(parseCustomEquipment(null), isEmpty);
    });

    test('populated JSON-string array parses to its items', () {
      final result = parseCustomEquipment('["Resistance Band","Dip Belt"]');
      expect(result, ['Resistance Band', 'Dip Belt']);
    });

    test('native List passes through as strings', () {
      final result = parseCustomEquipment(['Kettlebell', 'Sled']);
      expect(result, ['Kettlebell', 'Sled']);
    });

    test('native empty List stays empty', () {
      expect(parseCustomEquipment(<String>[]), isEmpty);
    });

    test('malformed JSON string falls back to empty list, not a crash', () {
      expect(parseCustomEquipment('not json'), isEmpty);
    });
  });
}
