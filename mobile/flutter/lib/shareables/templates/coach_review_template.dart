import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// CoachReview — handwritten coach's report-card on lined paper.
/// Letter grade top-right with a sparkle accent, three rubric categories
/// with checkmarks, and a signed footer. **No "AI" wording anywhere** —
/// the sparkle icon does the lifting. Spark category.
class CoachReviewTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const CoachReviewTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const Color _paper = Color(0xFFFFFEF7);
  static const Color _ruling = Color(0xFFE6E1D2);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _redInk = Color(0xFFB91C1C);

  String _grade(Shareable d) {
    // Map highlight count + presence of streak/PRs to a letter grade.
    final populated = d.highlights.where((h) => h.isPopulated).length;
    final hasStreak = d.highlights
        .any((h) => h.label.toUpperCase().contains('STREAK'));
    final hasPR =
        d.highlights.any((h) => h.label.toUpperCase().contains('PR'));
    var score = populated * 18;
    if (hasStreak) score += 8;
    if (hasPR) score += 12;
    if (score >= 95) return 'A+';
    if (score >= 88) return 'A';
    if (score >= 80) return 'A-';
    if (score >= 72) return 'B+';
    if (score >= 65) return 'B';
    return 'B-';
  }

  String _note(Shareable d) {
    final name = (d.userDisplayName ?? '').trim();
    final period = d.periodLabel.trim().isEmpty ? 'this week' : d.periodLabel;
    final hero = shareableHeroString(d);
    final unit = shareableHeroUnit(d);
    final salutation = name.isEmpty ? 'Friend' : name;
    if (hero == '—' || hero.isEmpty) {
      return '$salutation — solid effort in $period. Keep showing up.';
    }
    final detail = unit.isEmpty ? hero : '$hero $unit';
    return '$salutation — you put $detail on the board in $period. '
        'Form held, recovery looked dialed. Stay greedy.';
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final highlights =
        data.highlights.where((h) => h.isPopulated).take(3).toList();
    final grade = _grade(data);
    final note = _note(data);

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [_paper, _paper, _paper],
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _RuledLines()),
          // Red margin line.
          Positioned(
            left: 56,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1.4,
              color: _redInk.withValues(alpha: 0.55),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 64, 32, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 18 * mul,
                                color: accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'COACH REVIEW',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11 * mul,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.periodLabel.toUpperCase(),
                            style: TextStyle(
                              color: _ink.withValues(alpha: 0.55),
                              fontSize: 11 * mul,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _gradeBadge(grade, accent, mul),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  note,
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    color: _ink,
                    fontSize: 17 * mul,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _ink.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RUBRIC',
                        style: TextStyle(
                          color: _redInk,
                          fontSize: 10 * mul,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _rubricRow('Form', _grade(data), mul, accent),
                      _rubricRow('Volume', _grade(data), mul, accent),
                      _rubricRow('Consistency', _grade(data), mul, accent),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (highlights.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: highlights
                        .map((h) => _stickerNote(h, mul, accent))
                        .toList(),
                  ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 160,
                            height: 1,
                            color: _ink.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '— Coach',
                                style: TextStyle(
                                  fontFamily: 'Times New Roman',
                                  color: _ink,
                                  fontSize: 14 * mul,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.auto_awesome,
                                  size: 14 * mul, color: accent),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (showWatermark)
                      FitWizWatermark(
                        textColor: _ink,
                        fontSize: 12 * mul,
                        iconSize: 18,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeBadge(String grade, Color accent, double mul) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.06,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _redInk, width: 3),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              grade,
              style: TextStyle(
                fontFamily: 'Times New Roman',
                color: _redInk,
                fontSize: 56,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
            Icon(Icons.auto_awesome, size: 14 * mul, color: accent),
          ],
        ),
      ],
    );
  }

  Widget _rubricRow(String label, String grade, double mul, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16 * mul, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Times New Roman',
                color: _ink,
                fontSize: 14 * mul,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            grade,
            style: TextStyle(
              fontFamily: 'Times New Roman',
              color: _redInk,
              fontSize: 14 * mul,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickerNote(ShareableMetric m, double mul, Color accent) {
    return Transform.rotate(
      angle: ((m.label.length * 0.013) - 0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: accent.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
        child: Text(
          '${m.label}: ${m.value}',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            color: _ink,
            fontSize: 12 * mul,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _RuledLines extends StatelessWidget {
  const _RuledLines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RuledPainter());
  }
}

class _RuledPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CoachReviewTemplate._ruling
      ..strokeWidth = 1;
    for (double y = 96; y < size.height - 30; y += 36) {
      canvas.drawLine(Offset(40, y), Offset(size.width - 24, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
