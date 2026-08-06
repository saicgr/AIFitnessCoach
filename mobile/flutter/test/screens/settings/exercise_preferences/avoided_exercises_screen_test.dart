import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/settings/exercise_preferences/avoided_exercises_screen.dart';

// REGRESSION (E2E settings row 82): the avoided-exercises card printed the
// stored `reason` column verbatim. Manual avoids are free text (fine as-is),
// but the in-workout "report pain" flow writes a machine token
// (`pain:$severity`, avoided_provider.dart) never meant for display — it
// showed up as the literal string "pain:sharp". The end date was also
// formatted D/M/Y (`endDate.day/month/year`), which reads as the wrong date
// to a US-convention reader.
void main() {
  group('humanizeAvoidReason', () {
    test('humanizes the pain:sharp machine token', () {
      expect(humanizeAvoidReason('pain:sharp'), 'Reported sharp pain');
    });

    test('humanizes pain:mild', () {
      expect(humanizeAvoidReason('pain:mild'), 'Reported mild pain');
    });

    test('humanizes pain:severe', () {
      expect(humanizeAvoidReason('pain:severe'), 'Reported severe pain');
    });

    test('passes through genuine free text unchanged', () {
      expect(humanizeAvoidReason('Bad for my shoulder'), 'Bad for my shoulder');
    });

    test('unknown pain severity still humanizes instead of leaking the token', () {
      final result = humanizeAvoidReason('pain:unknown_future_value');
      expect(result, isNot(contains('pain:')));
    });
  });

  group('formatAvoidUntilDate', () {
    test('formats as unambiguous "MMM d, yyyy", not D/M/Y digits', () {
      final result = formatAvoidUntilDate(DateTime(2026, 8, 19));
      expect(result, 'Aug 19, 2026');
      expect(result, isNot(contains('19/8')));
    });
  });
}
