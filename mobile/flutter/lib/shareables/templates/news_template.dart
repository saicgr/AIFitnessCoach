import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// News — newspaper-style editorial that **fills the entire canvas** with
/// cream paper. Previous version centered a small ~400pt card on a
/// charcoal void, wasting ~70% of the 1080×1920 canvas. This version
/// paints the cream backdrop edge-to-edge and lays out a real masthead
/// + headline + (multi-column on portrait/square) body + by-the-numbers
/// stats strip + signed footer.
///
/// Headline goes through `shareableHeroString`/`shareableHeroUnit` so
/// pluralization is correct.
class NewsTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const NewsTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const Color _cream = Color(0xFFF1ECDF);
  static const Color _ink = Color(0xFF111111);
  static const Color _redInk = Color(0xFF8B0000);

  @override
  Widget build(BuildContext context) {
    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [_cream, _cream, _cream],
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _PaperGrain()),
          Padding(
            padding: _padding,
            child: _content(),
          ),
        ],
      ),
    );
  }

  EdgeInsets get _padding {
    switch (data.aspect) {
      case ShareableAspect.square:
        return const EdgeInsets.fromLTRB(36, 36, 36, 28);
      case ShareableAspect.portrait:
        return const EdgeInsets.fromLTRB(48, 56, 48, 36);
      case ShareableAspect.story:
        return const EdgeInsets.fromLTRB(48, 88, 48, 56);
    }
  }

  double get _bodyMul => data.aspect.bodyFontMultiplier;

  double get _headlineSize {
    switch (data.aspect) {
      case ShareableAspect.story:
        return 56;
      case ShareableAspect.portrait:
        return 46;
      case ShareableAspect.square:
        return 38;
    }
  }

  Widget _content() {
    final useTwoColumns = data.aspect != ShareableAspect.story;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _masthead(),
        const SizedBox(height: 18),
        _bylineRule(),
        const SizedBox(height: 14),
        Text(
          'EXCLUSIVE REPORT',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 12 * _bodyMul,
            fontWeight: FontWeight.w900,
            color: _redInk,
            letterSpacing: 2.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _headline(data),
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: _headlineSize,
            fontWeight: FontWeight.w900,
            height: 1.04,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: useTwoColumns ? _twoColumnBody() : _singleColumnBody(),
        ),
        const SizedBox(height: 18),
        _byTheNumbers(),
        const SizedBox(height: 18),
        _signOff(),
      ],
    );
  }

  Widget _masthead() {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _ink, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            data.periodLabel.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 11 * _bodyMul,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: 1.4,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'THE ZEALOVA TIMES',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: data.aspect == ShareableAspect.story ? 34 : 28,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
          Text(
            'NO. 01',
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 11 * _bodyMul,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bylineRule() {
    return Container(
      height: 1,
      color: _ink.withValues(alpha: 0.4),
      margin: const EdgeInsets.only(top: 2),
    );
  }

  Widget _singleColumnBody() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        _body(data),
        style: TextStyle(
          fontFamily: 'Times New Roman',
          fontSize: 15 * _bodyMul,
          height: 1.5,
          color: _ink,
        ),
      ),
    );
  }

  Widget _twoColumnBody() {
    final body = _body(data);
    final mid = body.length ~/ 2;
    final breakIdx = body.indexOf('. ', mid);
    final cut = breakIdx == -1 ? mid : breakIdx + 2;
    final left = body.substring(0, cut).trim();
    final right = body.substring(cut).trim();
    final style = TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 14 * _bodyMul,
      height: 1.5,
      color: _ink,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(left, style: style)),
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: _ink.withValues(alpha: 0.25),
        ),
        Expanded(child: Text(right, style: style)),
      ],
    );
  }

  Widget _byTheNumbers() {
    final stats = data.highlights.where((h) => h.isPopulated).take(3).toList();
    if (stats.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: _ink, width: 1.5),
          bottom: const BorderSide(color: _ink, width: 1.5),
        ),
        color: _ink.withValues(alpha: 0.02),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'BY THE\nNUMBERS',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 10 * _bodyMul,
                fontWeight: FontWeight.w900,
                color: _redInk,
                letterSpacing: 2,
                height: 1.1,
              ),
            ),
          ),
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(child: _stat(stats[i])),
            if (i < stats.length - 1)
              Container(
                width: 1,
                height: 36,
                color: _ink.withValues(alpha: 0.25),
              ),
          ],
        ],
      ),
    );
  }

  Widget _stat(ShareableMetric m) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 22 * _bodyMul,
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            m.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 10 * _bodyMul,
              fontWeight: FontWeight.w700,
              color: _ink.withValues(alpha: 0.6),
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOff() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '— ${(data.userDisplayName ?? data.title).toUpperCase()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontWeight: FontWeight.w700,
              fontSize: 12 * _bodyMul,
              letterSpacing: 1.4,
              color: _ink.withValues(alpha: 0.7),
            ),
          ),
        ),
        if (showWatermark)
          AppWatermark(
            textColor: _ink,
            iconSize: 18,
            fontSize: 12 * _bodyMul,
          ),
      ],
    );
  }

  String _headline(Shareable d) {
    final fullName = (d.userDisplayName ?? '').trim();
    final firstName = fullName.isEmpty
        ? ''
        : fullName.split(RegExp(r'\s+')).first;
    final period = d.periodLabel.trim().isEmpty ? 'this month' : d.periodLabel;
    // Use the user's first name as the subject. Falls back to "Athlete"
    // when display name is missing (was "Local lifter" — too generic).
    final subject = firstName.isEmpty ? 'Athlete' : firstName;
    final workoutTitle = d.title.trim();

    // Prefer a workout-specific headline using real numbers from the
    // session ("Awesome crushes Steady Ground Strength: 5 exercises, 12
    // reps, 46s"). Falls back to the old volume-led headline for non-
    // workout shares.
    final exerciseCount = d.exercises?.length ?? 0;
    String? duration;
    String? totalSets;
    String? totalReps;
    String? volume;
    for (final h in d.highlights) {
      final upper = h.label.toUpperCase();
      if (duration == null && (upper.contains('DURATION') || upper.contains('TIME'))) {
        duration = h.value;
      } else if (totalSets == null && upper.contains('SETS')) {
        totalSets = h.value;
      } else if (totalReps == null && upper.contains('REPS')) {
        totalReps = h.value;
      } else if (volume == null && upper.contains('VOLUME')) {
        volume = h.value;
      }
    }

    if (workoutTitle.isNotEmpty && exerciseCount > 0) {
      final stats = <String>[];
      if (totalSets != null) stats.add('$totalSets sets');
      if (totalReps != null) stats.add('$totalReps reps');
      if (duration != null) stats.add('in $duration');
      if (volume != null) stats.add('· $volume');
      final tail = stats.isEmpty ? '' : ' — ${stats.join(', ')}';
      return '$subject crushes $workoutTitle$tail';
    }

    final hero = shareableHeroString(d);
    final unit = shareableHeroUnit(d);
    if (hero == '—' && firstName.isEmpty) {
      return '${d.title} report — $period';
    }
    if (unit.isEmpty) {
      return '$subject hits $hero in $period';
    }
    return '$subject logs $hero $unit in $period';
  }

  String _body(Shareable d) {
    final highlights = d.highlights.where((h) => h.isPopulated).toList();
    final exercises = d.exercises ?? const [];

    // Build a real per-exercise breakdown sentence from logged sets.
    String? exerciseBreakdown;
    if (exercises.isNotEmpty) {
      final namedSets = exercises.where((e) => e.sets.isNotEmpty).take(4).map((e) {
        final completedSets = e.sets.where((s) => s.reps > 0).toList();
        if (completedSets.isEmpty) return '${e.name} (logged)';
        final sample = completedSets.first;
        final isBw = sample.weight == null || sample.weight == 0;
        final weightStr = isBw
            ? 'BW'
            : '${sample.weight!.toStringAsFixed(sample.weight! == sample.weight!.roundToDouble() ? 0 : 1)} ${sample.unit}';
        return '${e.name} — ${completedSets.length}×${sample.reps} @ $weightStr';
      }).toList();
      if (namedSets.isNotEmpty) {
        final extra = exercises.length - namedSets.length;
        final tail = extra > 0 ? ', and $extra more' : '';
        exerciseBreakdown = 'On the docket: ${namedSets.join('; ')}$tail.';
      }
    }

    if (highlights.isEmpty && exerciseBreakdown == null) {
      return 'Numbers climb. Discipline compounds. ${Branding.appName} captured the receipts '
          'so every rep, every minute, every win shows up exactly where it '
          'belongs — in the record. Witnesses report a steady cadence of '
          'effort, no shortcuts taken, no reps skipped. The story is on the '
          'page; the proof is in the log.';
    }

    final stats = highlights.take(4).map((h) {
      return '${h.label.toLowerCase()} ${h.value}';
    }).join(' · ');

    final lead = stats.isNotEmpty
        ? 'The session is in the books — $stats. '
        : 'The session is in the books. ';
    final detail = exerciseBreakdown ?? '';
    final closer = exerciseBreakdown != null
        ? ' Sources close to the lifter say consistency is the real headline.'
        : ' Sources close to the lifter say consistency is the real headline — work shows up in the log even when motivation doesn\'t.';

    return '$lead$detail$closer';
  }
}

/// Hairline diagonal fibers + a faint corner stamp to sell the "real paper"
/// feel without overwhelming the type. Drawn at full canvas size.
class _PaperGrain extends StatelessWidget {
  const _PaperGrain();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PaperGrainPainter());
  }
}

class _PaperGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.04)
      ..strokeWidth = 0.7;
    for (double y = 0; y < size.height; y += 9) {
      final off = ((y * 13.7) % 17) - 8;
      canvas.drawLine(
        Offset(0, y + off),
        Offset(size.width, y + off * 0.6),
        paint,
      );
    }
    // Faint corner stamp (top-right) — like a registration mark.
    final stampPaint = Paint()
      ..color = const Color(0xFF8B0000).withValues(alpha: 0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final c = Offset(size.width - 56, 56);
    canvas.drawCircle(c, 22, stampPaint);
    canvas.drawCircle(c, 30, stampPaint..color = stampPaint.color.withValues(alpha: 0.10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
