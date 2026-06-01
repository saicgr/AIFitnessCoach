import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/repositories/chat_repository.dart';

void main() {
  group('looksLikeQuickWorkoutRequest (drives optimistic skeleton)', () {
    test('matches the user\'s real workout-generation phrasings', () {
      const positives = [
        'I want to do a quick 10 min workout with kettlebell only',
        'Generate me a workout using hay bale',
        'make me a workout',
        'give me a 20 minute leg workout',
        'create a workout',
        'build me a workout',
        'do a workout with dumbbells',
        '15 minute hiit workout',
      ];
      for (final m in positives) {
        expect(ChatMessagesNotifier.looksLikeQuickWorkoutRequest(m), isTrue,
            reason: 'should detect: "$m"');
      }
    });

    test('does NOT match non-workout messages (no false skeleton)', () {
      const negatives = [
        'how did I sleep last night',
        'what should I eat for lunch',
        'thanks coach',
        'show me my steps this week',
        'what is my resting heart rate',
      ];
      for (final m in negatives) {
        expect(ChatMessagesNotifier.looksLikeQuickWorkoutRequest(m), isFalse,
            reason: 'should NOT detect: "$m"');
      }
    });
  });
}
