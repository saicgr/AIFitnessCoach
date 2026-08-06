/// Regression test for Home → metrics carousel → TRAINING page (E2E row
/// 134, MED).
///
/// `TrainingCard`'s STREAK slot is the app-open (login) streak, not a
/// training streak — but sitting beside "1 OF 4 sessions this week" a bare
/// "STREAK" reads as consecutive training days, directly contradicting the
/// sessions ring on the same card. Pins the label names what it actually
/// measures.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/providers/metrics_carousel_data_provider.dart';
import 'package:fitwiz/screens/home/widgets/metrics_carousel/metrics_carousel_cards.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('the streak slot label names it as a login streak, not a bare '
      '"STREAK" that reads as training days', (tester) async {
    const stats = TrainingWeekStats(
      sessionsCompleted: 1,
      sessionsScheduled: 4,
      streakDays: 5,
      volumeKg: 0,
      totalMinutes: 20,
      newPrsThisWeek: 0,
      caloriesBurned: 0,
      exercisesDone: 0,
    );
    await tester.pumpWidget(createTestWidget(
      const TrainingCard(stats: stats, slots: []),
    ));
    await tester.pump();

    expect(find.text('LOGIN STREAK'), findsOneWidget,
        reason: 'must disambiguate from a training streak — E2E row 134: '
            '"STREAK 5 days" beside "1 OF 4 sessions" read as a training '
            'contradiction on the same card');
    expect(find.text('STREAK'), findsNothing);
  });
}
