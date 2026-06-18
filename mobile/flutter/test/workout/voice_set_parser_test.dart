import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/voice_set_logging.dart';

void main() {
  group('VoiceSetParser', () {
    void expectWR(String input, double? w, int? r) {
      final p = VoiceSetParser.parse(input);
      if (w == null) {
        expect(p.weight, isNull, reason: input);
      } else {
        expect(p.weight, isNotNull, reason: input);
        expect((p.weight! - w).abs() < 0.01, isTrue,
            reason: '$input weight=${p.weight} exp=$w');
      }
      expect(p.reps, r, reason: '$input reps');
    }

    test('digit forms', () {
      expectWR('225 for 8', 225, 8);
      expectWR('225 by 8', 225, 8);
      expectWR('225x8', 225, 8);
      expectWR('225 x 8', 225, 8);
      expectWR('185 for 5', 185, 5);
    });
    test('word forms', () {
      expectWR('two twenty five for eight', 225, 8);
      expectWR('one hundred for twelve', 100, 12);
    });
    test('unit + rep words', () {
      expectWR('135 pounds 10 reps', 135, 10);
    });
    test('reps only', () {
      expectWR('8 reps', null, 8);
    });
    test('empty', () {
      expect(VoiceSetParser.parse('').isEmpty, isTrue);
    });
  });
}
