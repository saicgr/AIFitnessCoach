import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Instagram-Story template: "This Week's PRs".
/// Gold/orange "trophy" theme. Falls back to an encouragement message when
/// no PRs were set (zero-PR weeks are common — do not hide this slide).
class WeeklyPrsTemplate extends StatelessWidget {
  /// Parsed PR entries from `WeeklySummary.prDetails` (raw `List<Map>?`).
  /// Each entry should have `exercise_name` and `detail` keys.
  final List<Map<String, dynamic>> prDetails;
  final int prsAchieved;
  final String dateRangeLabel;
  final bool showWatermark;

  const WeeklyPrsTemplate({
    super.key,
    required this.prDetails,
    required this.prsAchieved,
    required this.dateRangeLabel,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrs = prsAchieved > 0 && prDetails.isNotEmpty;
    final visiblePrs = prDetails.take(4).toList();

    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1008),
            Color(0xFF422006),
            Color(0xFF1A1008),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RaysPainter())),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'NEW',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateRangeLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'PERSONAL RECORDS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: _TrophyBadge(count: prsAchieved),
                ),
                const SizedBox(height: 24),
                if (hasPrs) ...[
                  for (int i = 0; i < visiblePrs.length; i++) ...[
                    _PrRow(
                      rank: i + 1,
                      exercise: (visiblePrs[i]['exercise_name'] ?? 'Exercise')
                          .toString(),
                      detail: (visiblePrs[i]['detail'] ?? '').toString(),
                    ),
                    if (i < visiblePrs.length - 1) const SizedBox(height: 6),
                  ],
                  if (prsAchieved > visiblePrs.length)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+ ${prsAchieved - visiblePrs.length} more',
                        style: TextStyle(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ] else
                  _EmptyPrState(),
                const Spacer(),
                if (showWatermark) const AppWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyBadge extends StatelessWidget {
  final int count;
  const _TrophyBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFCD34D), Color(0xFFD97706)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 48,
          ),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count == 1 ? '1 PR' : '$count PRs',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrRow extends StatelessWidget {
  final int rank;
  final String exercise;
  final String detail;

  const _PrRow({
    required this.rank,
    required this.exercise,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              exercise,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (detail.isNotEmpty)
            Text(
              detail,
              style: TextStyle(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPrState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center_rounded,
              color: const Color(0xFFFBBF24).withValues(alpha: 0.8), size: 28),
          const SizedBox(height: 8),
          const Text(
            'No PRs this week',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Showing up is the win. Next week is yours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle diagonal sunbeam rays radiating from the top-center of the card.
class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBBF24).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.3),
        radius: size.width * 0.7,
      ));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
