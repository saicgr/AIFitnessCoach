import 'package:flutter/material.dart';
import '_share_common.dart';

/// Receipt — monospaced "gym receipt" parody. Line items per exercise
/// with sets × reps, subtotal row, and "thank you come again" footer.
class ReceiptTemplate extends StatelessWidget {
  final String workoutName;
  final List<ShareExerciseSummary> exercises;
  final int durationSeconds;
  final int totalSets;
  final double? totalVolumeKg;
  final int? calories;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const ReceiptTemplate({
    super.key,
    required this.workoutName,
    this.exercises = const [],
    required this.durationSeconds,
    required this.totalSets,
    this.totalVolumeKg,
    this.calories,
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';
    const fontFamily = 'monospace';
    const darkInk = Color(0xFF1A1A1A);
    final receiptBg = const Color(0xFFF5F1E8);

    return Container(
      color: const Color(0xFF000000),
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: BoxDecoration(
          color: receiptBg,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                '**  FITWIZ GYM  **',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: darkInk,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _formatReceiptDate(completedAt),
                style: const TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 11,
                  color: darkInk,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                '─────────────────────────────',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 11,
                  color: darkInk.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ORDER: ${workoutName.toUpperCase()}',
              style: const TextStyle(
                fontFamily: fontFamily,
                fontSize: 11,
                color: darkInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            // Line items
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.isEmpty ? 1 : exercises.take(7).length,
                itemBuilder: (context, i) {
                  if (exercises.isEmpty) {
                    return const Text(
                      'No exercises logged',
                      style: TextStyle(fontFamily: fontFamily, fontSize: 11, color: darkInk),
                    );
                  }
                  final ex = exercises[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ex.name.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 11,
                              color: darkInk,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${ex.sets}x${ex.reps}',
                          style: const TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 11,
                            color: darkInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Text(
              '─────────────────────────────',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 11,
                color: darkInk.withValues(alpha: 0.7),
              ),
            ),
            _row('DURATION', formatShareDurationLong(durationSeconds)),
            _row('TOTAL SETS', '$totalSets'),
            if (calories != null) _row('CALORIES', '$calories kcal'),
            _row(
              'TOTAL VOLUME',
              totalVolumeKg == null
                  ? '—'
                  : formatShareWeight(totalVolumeKg, useKg: useKg),
              bold: true,
            ),
            const SizedBox(height: 8),
            Text(
              '─────────────────────────────',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 11,
                color: darkInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'THANK YOU — COME AGAIN',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 11,
                  color: darkInk,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (showWatermark)
              Center(
                child: Text(
                  '| | | | | | | | | | | | | | | | | |',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    color: darkInk.withValues(alpha: 0.8),
                    height: 1,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            if (showWatermark)
              const Center(
                child: Text(
                  'fitwiz',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 9,
                    color: darkInk,
                    letterSpacing: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    const fontFamily = 'monospace';
    const darkInk = Color(0xFF1A1A1A);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              color: darkInk,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              color: darkInk,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatReceiptDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.month}/${d.day}/${d.year}  $h:$m';
  }
}
