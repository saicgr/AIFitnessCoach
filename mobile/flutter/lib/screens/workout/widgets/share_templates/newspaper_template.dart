import 'package:flutter/material.dart';
import '_share_common.dart';

/// Newspaper — broadsheet front-page parody. Serif bold headline
/// plus fake sub-article with workout stats. Grayscale newsprint.
class NewspaperTemplate extends StatelessWidget {
  final String workoutName;
  final String? userDisplayName;
  final double? totalVolumeKg;
  final int totalSets;
  final int durationSeconds;
  final int exercisesCount;
  final List<ShareExerciseSummary> exercises;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const NewspaperTemplate({
    super.key,
    required this.workoutName,
    this.userDisplayName,
    this.totalVolumeKg,
    required this.totalSets,
    required this.durationSeconds,
    required this.exercisesCount,
    this.exercises = const [],
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';
    final name = (userDisplayName ?? 'A LOCAL LIFTER').toUpperCase();
    final volLabel = totalVolumeKg == null
        ? '—'
        : formatShareWeight(totalVolumeKg, useKg: useKg);
    final comparison = totalVolumeKg == null
        ? ''
        : comparisonCopyForVolume(
            useKg ? totalVolumeKg! : totalVolumeKg! * 2.20462,
            useKg: useKg,
          );

    final topEx = exercises.isNotEmpty ? exercises.first.name : workoutName;

    return Container(
      color: const Color(0xFFEDE6D3),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'serif',
          color: Color(0xFF0F0F0F),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Masthead
            Center(
              child: Text(
                'THE FITWIZ TIMES',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Center(
              child: Text(
                '${_formatDate(completedAt)}  ·  Vol. ${completedAt.year}  ·  Price \$0.00',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(height: 2, color: Colors.black),
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 1,
              color: Colors.black,
            ),
            const SizedBox(height: 14),
            // Headline
            Text(
              '$name LIFTS $volLabel IN GRUELING SESSION',
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '"Experts stunned by ${topEx.toLowerCase()} performance"',
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            // Two-column body
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: article
                  Expanded(
                    flex: 3,
                    child: Text(
                      _articleText(name, volLabel, comparison, workoutName),
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Vertical rule
                  Container(width: 0.8, color: Colors.black),
                  const SizedBox(width: 12),
                  // Right: stat sidebar
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THE NUMBERS',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(height: 0.8, color: Colors.black),
                        const SizedBox(height: 6),
                        _row('Duration', formatShareDurationLong(durationSeconds)),
                        _row('Exercises', '$exercisesCount'),
                        _row('Total sets', '$totalSets'),
                        _row('Volume', volLabel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.black),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Continued on page ${completedAt.day + 1}',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (showWatermark)
                  const Text(
                    'fitwiz',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 10,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _articleText(String name, String vol, String comparison, String wk) {
    final capsName = name;
    final intro = 'In a display of raw determination, $capsName reportedly '
        'completed a $wk session clocking in at $vol of total work. '
        'Witnesses described the effort as "impressive," ';
    final punchline = comparison.isEmpty
        ? 'and unprecedented for a single session.'
        : 'equivalent to hoisting $comparison into the air.';
    final closer = '\n\nSources at the scene could not confirm whether '
        'the athlete was seen drinking a protein shake afterwards, but '
        'experts agree such a finish is "probable."';
    return intro + punchline + closer;
  }

  String _formatDate(DateTime d) {
    const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY',
                    'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER',
                    'NOVEMBER', 'DECEMBER'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
