import 'dart:math';
import 'package:flutter/material.dart';
import 'progress_share_data.dart';
import 'progress_share_primitives.dart';

// =============================================================================
// 1. IG Story CTA — matches the Instagram story reference exactly:
//    two photos stacked, dates overlaid, "START NOW" link pill at bottom.
// =============================================================================

class IgStoryCtaTemplate extends StatelessWidget {
  final ProgressShareData data;
  final String ctaText;
  final bool showWatermark;

  const IgStoryCtaTemplate({
    super.key,
    required this.data,
    this.ctaText = 'START NOW',
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      backgroundColor: Colors.black,
      child: Stack(children: [
        Column(children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: ProgressShareImage(url: data.before.photoUrl)),
              Positioned(
                right: 16, bottom: 16,
                child: _dateChip(formatCompactDate(data.beforeDate)),
              ),
            ]),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: ProgressShareImage(url: data.after.photoUrl)),
              Positioned(
                left: 16, top: 16,
                child: _dateChip(formatCompactDate(data.afterDate)),
              ),
              Positioned(
                left: 0, right: 0, bottom: 28,
                child: Center(child: _ctaPill(ctaText)),
              ),
            ]),
          ),
        ]),
        if (showWatermark)
          Positioned(
            left: 12, top: 12,
            child: ProgressShareWatermark(color: Colors.white.withValues(alpha: 0.95)),
          ),
      ]),
    );
  }

  Widget _dateChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3)],
    ),
    child: Text(text, style: const TextStyle(
      color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13,
    )),
  );

  Widget _ctaPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.link, color: Colors.white, size: 13),
      ),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(
        color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2,
      )),
    ]),
  );
}

// =============================================================================
// 2. Wrapped — Spotify-Wrapped bold typography on a warm duotone.
// =============================================================================

class WrappedTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const WrappedTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFFFF4D8D), Color(0xFF8A2BE2), Color(0xFF00E5FF)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (showWatermark) const ProgressShareWatermark(color: Colors.white, compact: true),
            const Spacer(),
            Text(data.afterDate.year.toString(), style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 3,
            )),
          ]),
          const SizedBox(height: 12),
          const Text('MY TRANSFORMATION',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 4)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.75,
                child: ProgressShareImage(
                  url: data.before.photoUrl,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.75,
                child: ProgressShareImage(
                  url: data.after.photoUrl,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Text(data.durationText.toUpperCase(), style: const TextStyle(
            color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 0.95, letterSpacing: -1,
          )),
          const SizedBox(height: 4),
          Text('of discipline.'.toUpperCase(), style: const TextStyle(
            color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2,
          )),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _wrappedStat(data.totalWorkouts.toString(), 'WORKOUTS'),
            _wrappedStat('${data.currentStreak}', 'DAY STREAK'),
            if (data.weightDeltaKg != null) _wrappedStat(data.weightLostText.split(' ').first, data.useKg ? 'KG' : 'LB'),
          ]),
        ]),
      ),
    );
  }

  Widget _wrappedStat(String v, String l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30, height: 1)),
    Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
  ]);
}

// =============================================================================
// 3. Receipt — paper-receipt parody with monospace, dashed rules.
// =============================================================================

class ReceiptTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const ReceiptTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      backgroundColor: const Color(0xFFEFEAE0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: Text('FITWIZ MARKET', style: TextStyle(
            fontFamily: 'Courier', fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3,
          ))),
          const SizedBox(height: 2),
          Center(child: Text(formatPrettyDate(data.afterDate), style: const TextStyle(
            fontFamily: 'Courier', fontSize: 11, color: Colors.black87,
          ))),
          const SizedBox(height: 12),
          const _DashedLine(),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AspectRatio(aspectRatio: 1, child: ProgressShareImage(url: data.before.photoUrl))),
            const SizedBox(width: 6),
            Expanded(child: AspectRatio(aspectRatio: 1, child: ProgressShareImage(url: data.after.photoUrl))),
          ]),
          const SizedBox(height: 10),
          const _DashedLine(),
          const SizedBox(height: 10),
          _receiptRow('DURATION', data.durationText),
          _receiptRow('WORKOUTS', '${data.totalWorkouts}'),
          _receiptRow('STREAK', '${data.currentStreak} days'),
          if (data.weightDeltaKg != null)
            _receiptRow('WEIGHT Δ', data.weightDeltaText),
          const SizedBox(height: 8),
          const _DashedLine(),
          const SizedBox(height: 8),
          _receiptRow('SUBTOTAL', 'WORTH IT'),
          _receiptRow('TAX', 'SWEAT'),
          _receiptRow('TOTAL', 'SHIPPED', bold: true),
          const SizedBox(height: 10),
          const _DashedLine(),
          const SizedBox(height: 12),
          const Center(child: Text('*** THANK YOU ***', style: TextStyle(
            fontFamily: 'Courier', fontSize: 11, fontWeight: FontWeight.bold,
          ))),
          const SizedBox(height: 8),
          Center(child: _barcode()),
          const Spacer(),
          if (showWatermark) const Center(child: ProgressShareWatermark(color: Colors.black87, compact: true)),
        ]),
      ),
    );
  }

  Widget _receiptRow(String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(children: [
      Expanded(child: Text(l, style: TextStyle(
        fontFamily: 'Courier', fontSize: 12,
        fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      ))),
      Text(v, style: TextStyle(
        fontFamily: 'Courier', fontSize: 12,
        fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      )),
    ]),
  );

  Widget _barcode() => Row(mainAxisSize: MainAxisSize.min, children: List.generate(22, (i) {
    final w = (i * 7 % 3) + 1.0;
    return Container(width: w, height: 24, margin: const EdgeInsets.symmetric(horizontal: 0.8), color: Colors.black);
  }));
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (ctx, c) {
    const dash = 5.0;
    const gap = 3.0;
    final count = (c.maxWidth / (dash + gap)).floor();
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(count, (_) => Container(
      width: dash, height: 1, margin: const EdgeInsets.only(right: gap), color: Colors.black87,
    )));
  });
}

// =============================================================================
// 4. Trading Card — Pokémon / baseball-style card with rarity frame.
// =============================================================================

class TradingCardTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const TradingCardTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFFFD700);
    return ProgressTemplateCanvas(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF1A1000), Color(0xFF0F0700)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [gold, const Color(0xFFFFAA00), gold],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1410),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Text(data.username?.toUpperCase() ?? 'THE TRANSFORMATION', style: TextStyle(
                  color: gold, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2,
                )),
                const Spacer(),
                _rarityBadge('LEGENDARY', gold),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: Row(children: [
                  Expanded(child: ProgressShareImage(url: data.before.photoUrl, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(width: 6),
                  Expanded(child: ProgressShareImage(url: data.after.photoUrl, borderRadius: BorderRadius.circular(8))),
                ]),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.08),
                  border: Border.all(color: gold.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  _statRow('DISCIPLINE', data.durationText.toUpperCase(), gold),
                  const SizedBox(height: 4),
                  _statRow('VOLUME', '${data.totalWorkouts} RUNS', gold),
                  const SizedBox(height: 4),
                  _statRow('STREAK', '${data.currentStreak} DAYS', gold),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text('#${data.daysBetween}', style: TextStyle(color: gold.withValues(alpha: 0.6), fontWeight: FontWeight.w900, fontSize: 12)),
                const Spacer(),
                if (showWatermark) ProgressShareWatermark(color: gold.withValues(alpha: 0.7), compact: true),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _rarityBadge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
    child: Text(t, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.5)),
  );

  Widget _statRow(String l, String v, Color c) => Row(children: [
    Text(l, style: TextStyle(color: c.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
    const Spacer(),
    Text(v, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w900)),
  ]);
}

// =============================================================================
// 5. Newspaper — tabloid front-page parody.
// =============================================================================

class NewspaperTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const NewspaperTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      backgroundColor: const Color(0xFFFAF6EC),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Text('THE DAILY GAINS', style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5,
              fontFamily: 'serif',
            )),
            const Spacer(),
            Text('VOL. ${data.totalWorkouts}', style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 10, fontFamily: 'serif',
            )),
          ]),
          Container(height: 2, color: Colors.black, margin: const EdgeInsets.symmetric(vertical: 2)),
          Container(height: 0.5, color: Colors.black, margin: const EdgeInsets.only(bottom: 10)),
          Row(children: [
            Text('${formatPrettyDate(data.afterDate).toUpperCase()}  ·  SPECIAL EDITION  ·  \$0.00', style: const TextStyle(
              fontSize: 9, fontFamily: 'serif',
            )),
          ]),
          const SizedBox(height: 10),
          Text(
            data.weightDeltaKg != null
                ? 'LOCAL LEGEND SHEDS ${data.weightLostText.toUpperCase()} IN ${data.durationText.toUpperCase()}'
                : 'LOCAL LEGEND TRANSFORMS IN ${data.durationText.toUpperCase()}',
            style: const TextStyle(
              fontFamily: 'serif', fontWeight: FontWeight.w900, fontSize: 22, height: 1, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: Row(children: [
            Expanded(child: AspectRatio(aspectRatio: 0.7, child: _photoWithCaption(data.before.photoUrl, 'BEFORE: ${formatCompactDate(data.beforeDate)}'))),
            const SizedBox(width: 8),
            Expanded(child: AspectRatio(aspectRatio: 0.7, child: _photoWithCaption(data.after.photoUrl, 'AFTER: ${formatCompactDate(data.afterDate)}'))),
          ])),
          const SizedBox(height: 10),
          const Text(
            'Sources close to the subject confirm the shift is due to consistent training, honest eating, and refusing to skip leg day. Experts call it "unprecedented dedication."',
            style: TextStyle(fontSize: 10, fontFamily: 'serif', height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(height: 0.5, color: Colors.black),
          const SizedBox(height: 6),
          Row(children: [
            const Text('REPORTED BY', style: TextStyle(fontSize: 9, fontFamily: 'serif', fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            if (showWatermark) const ProgressShareWatermark(color: Colors.black, compact: true),
          ]),
        ]),
      ),
    );
  }

  Widget _photoWithCaption(String url, String caption) => Column(children: [
    Expanded(child: ProgressShareImage(url: url)),
    const SizedBox(height: 3),
    Text(caption, style: const TextStyle(fontSize: 8, fontFamily: 'serif', fontWeight: FontWeight.w600)),
  ]);
}

// =============================================================================
// 6. Polaroid Diary — two stacked Polaroids with handwritten-feel caption.
// =============================================================================

class PolaroidDiaryTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const PolaroidDiaryTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      gradient: const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFF5E9D4), Color(0xFFE8D4B0)],
      ),
      child: Stack(children: [
        Positioned(
          left: 30, top: 40,
          child: Transform.rotate(angle: -0.08, child: _polaroid(data.before.photoUrl, formatCompactDate(data.beforeDate))),
        ),
        Positioned(
          right: 30, bottom: 110,
          child: Transform.rotate(angle: 0.06, child: _polaroid(data.after.photoUrl, formatCompactDate(data.afterDate))),
        ),
        Positioned(
          left: 20, right: 20, bottom: 28,
          child: Column(children: [
            Text('from ${data.durationText} ago', style: TextStyle(
              fontSize: 16, fontStyle: FontStyle.italic, color: Colors.brown.shade800,
            )),
            Text('to right now.', style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, color: Colors.brown.shade900,
              fontFamily: 'cursive',
            )),
            const SizedBox(height: 6),
            if (showWatermark) const ProgressShareWatermark(color: Colors.black54, compact: true),
          ]),
        ),
      ]),
    );
  }

  Widget _polaroid(String url, String caption) => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
    width: 170, height: 200,
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(3, 6))],
    ),
    child: Stack(children: [
      Positioned.fill(child: ProgressShareImage(url: url)),
      Positioned(bottom: -24, left: 0, right: 0, child: Center(child: Text(
        caption, style: TextStyle(
          fontSize: 12, fontStyle: FontStyle.italic, color: Colors.brown.shade700, fontFamily: 'cursive',
        ),
      ))),
    ]),
  );
}

// =============================================================================
// 7. Magazine Cover — glossy fashion-mag cover with hero photo + cover lines.
// =============================================================================

class MagazineCoverTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const MagazineCoverTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      backgroundColor: Colors.black,
      child: Stack(children: [
        Positioned.fill(child: ProgressShareImage(url: data.after.photoUrl)),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0, 0.4, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: 16, left: 16, right: 16,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('FITWIZ', style: TextStyle(
              color: Colors.white, fontFamily: 'serif', fontWeight: FontWeight.w900,
              fontSize: 38, letterSpacing: -1.5, height: 1,
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('ISSUE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Text('#${data.daysBetween}', style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
              )),
            ]),
          ]),
        ),
        Positioned(
          left: 16, top: 80, right: 140,
          child: Text(
            data.weightDeltaKg != null ? 'HOW SHE LOST ${data.weightLostText.toUpperCase()}' : 'THE ${data.durationText.toUpperCase()} GLOW-UP',
            style: const TextStyle(
              color: Color(0xFFFF2D6A), fontWeight: FontWeight.w900, fontSize: 24, height: 1,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Positioned(
          left: 16, top: 150,
          child: _coverLine('— WITHOUT GIVING UP CARBS'),
        ),
        Positioned(
          left: 16, bottom: 180,
          child: _coverLine('${data.currentStreak}-DAY STREAK', bold: true),
        ),
        Positioned(
          right: 16, bottom: 150,
          child: _coverLine('${data.totalWorkouts} workouts\nlogged'),
        ),
        Positioned(
          left: 16, right: 16, bottom: 24,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.durationText.toUpperCase(), style: const TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1,
              )),
              const Text('OF CONSISTENCY', style: TextStyle(
                color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3,
              )),
            ]),
            if (showWatermark) const ProgressShareWatermark(color: Colors.white, compact: true),
          ]),
        ),
      ]),
    );
  }

  Widget _coverLine(String t, {bool bold = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    color: bold ? const Color(0xFFFFD166) : Colors.black.withValues(alpha: 0.5),
    child: Text(t, style: TextStyle(
      color: bold ? Colors.black : Colors.white,
      fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, height: 1.2,
    )),
  );
}

// =============================================================================
// 8. Retro 80s — synthwave chrome-text + neon grid.
// =============================================================================

class Retro80sTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const Retro80sTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      gradient: const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF1E0B3A), Color(0xFF3A0B5A), Color(0xFFFF006E)],
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _SynthGridPainter())),
        Positioned(
          top: 32, left: 0, right: 0,
          child: Center(
            child: Text('TRANSFORMED', style: TextStyle(
              color: const Color(0xFFFFE9F1), fontSize: 34, fontWeight: FontWeight.w900,
              letterSpacing: 4, height: 1,
              shadows: const [
                Shadow(color: Color(0xFF00F6FF), offset: Offset(-2, 0), blurRadius: 0),
                Shadow(color: Color(0xFFFF006E), offset: Offset(2, 0), blurRadius: 0),
              ],
            )),
          ),
        ),
        Positioned(
          left: 24, right: 24, top: 90, bottom: 140,
          child: Row(children: [
            Expanded(child: _neonFrame(data.before.photoUrl)),
            const SizedBox(width: 10),
            Expanded(child: _neonFrame(data.after.photoUrl)),
          ]),
        ),
        Positioned(
          left: 0, right: 0, bottom: 90,
          child: Column(children: [
            Text(data.durationText.toUpperCase(), style: const TextStyle(
              color: Color(0xFF00F6FF), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 5,
            )),
            const SizedBox(height: 4),
            Text('${data.totalWorkouts} workouts · ${data.currentStreak}-day streak'.toUpperCase(), style: const TextStyle(
              color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
            )),
          ]),
        ),
        if (showWatermark)
          const Positioned(left: 0, right: 0, bottom: 24, child: Center(child: ProgressShareWatermark(color: Colors.white, compact: true))),
      ]),
    );
  }

  Widget _neonFrame(String url) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFFF006E), width: 2),
      boxShadow: const [BoxShadow(color: Color(0xFFFF006E), blurRadius: 12)],
    ),
    child: ProgressShareImage(url: url, fit: BoxFit.cover),
  );
}

class _SynthGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF00F6FF).withValues(alpha: 0.25)
      ..strokeWidth = 1;
    final horizon = size.height * 0.72;
    for (double y = horizon; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    for (double x = -size.width; x < size.width * 2; x += 30) {
      final dx = x + (x - size.width / 2) * 0.5;
      canvas.drawLine(Offset(size.width / 2, horizon), Offset(dx, size.height), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// =============================================================================
// 9. Neon Tabloid — high-contrast billboard / times-square style.
// =============================================================================

class NeonTabloidTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const NeonTabloidTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      backgroundColor: const Color(0xFF0D0015),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2DCE),
                boxShadow: const [BoxShadow(color: Color(0xFFFF2DCE), blurRadius: 20)],
              ),
              child: const Text('BREAKING', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 3,
              )),
            ),
            const SizedBox(height: 12),
            Text('+${data.totalWorkouts}\nWORKOUTS', style: const TextStyle(
              color: Color(0xFF00FFC6), fontSize: 56, fontWeight: FontWeight.w900, height: 0.9,
              letterSpacing: -2,
            )),
            const Spacer(),
            Row(children: [
              Expanded(child: AspectRatio(aspectRatio: 1, child: _glowFrame(data.before.photoUrl, const Color(0xFF00FFC6)))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 1, child: _glowFrame(data.after.photoUrl, const Color(0xFFFF2DCE)))),
            ]),
            const Spacer(),
            Text(data.durationText.toUpperCase(), style: const TextStyle(
              color: Color(0xFFFFE9F1), fontSize: 40, fontWeight: FontWeight.w900, height: 1,
              letterSpacing: -1,
            )),
            const Text('OF PURE WORK', style: TextStyle(
              color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
            )),
            const SizedBox(height: 10),
            if (showWatermark) const ProgressShareWatermark(color: Colors.white70, compact: true),
          ]),
        ),
      ]),
    );
  }

  Widget _glowFrame(String url, Color c) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: c, width: 2),
      boxShadow: [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 14)],
    ),
    child: ProgressShareImage(url: url),
  );
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (double x = 0; x < size.width; x += 16) {
      for (double y = 0; y < size.height; y += 16) {
        canvas.drawCircle(Offset(x, y), 0.8, p);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// =============================================================================
// 10. Swiss Editorial — minimalist grid-based layout with tight typography.
// =============================================================================

class SwissEditorialTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const SwissEditorialTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      backgroundColor: const Color(0xFFF2F2F2),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Text('001', style: TextStyle(fontFamily: 'Helvetica', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
            const Spacer(),
            Text(formatCompactDate(data.afterDate), style: const TextStyle(
              fontFamily: 'Helvetica', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
            )),
          ]),
          Container(height: 1, color: Colors.black, margin: const EdgeInsets.symmetric(vertical: 8)),
          const Text('A\nTRANSFORMATION\nSTUDY', style: TextStyle(
            color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1.5,
            fontFamily: 'Helvetica',
          )),
          const SizedBox(height: 16),
          Expanded(
            child: Row(children: [
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ProgressShareImage(url: data.before.photoUrl)),
                const SizedBox(height: 4),
                Text('FIG. 01 · ${formatCompactDate(data.beforeDate)}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontFamily: 'Helvetica')),
              ])),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ProgressShareImage(url: data.after.photoUrl)),
                const SizedBox(height: 4),
                Text('FIG. 02 · ${formatCompactDate(data.afterDate)}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontFamily: 'Helvetica')),
              ])),
            ]),
          ),
          Container(height: 1, color: Colors.black, margin: const EdgeInsets.symmetric(vertical: 10)),
          Row(children: [
            _swissStat('Δt', data.durationText),
            const SizedBox(width: 20),
            _swissStat('n', '${data.totalWorkouts}'),
            const SizedBox(width: 20),
            _swissStat('s', '${data.currentStreak}'),
            const Spacer(),
            if (showWatermark) const ProgressShareWatermark(color: Colors.black, compact: true),
          ]),
        ]),
      ),
    );
  }

  Widget _swissStat(String l, String v) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(l, style: const TextStyle(
      fontFamily: 'Helvetica', fontSize: 14, fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
    )),
    const SizedBox(width: 4),
    Text(v, style: const TextStyle(
      fontFamily: 'Helvetica', fontSize: 16, fontWeight: FontWeight.w900,
    )),
  ]);
}

// =============================================================================
// 11. Achievement Unlocked — video-game badge.
// =============================================================================

class AchievementUnlockedTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const AchievementUnlockedTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0B1020), Color(0xFF1F0F3A), Color(0xFF0B1020)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            ),
            child: const Text('ACHIEVEMENT UNLOCKED', style: TextStyle(
              color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3,
            )),
          ),
          const SizedBox(height: 22),
          Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(colors: [
                Color(0xFFFFD700), Color(0xFFFF9100), Color(0xFFFFD700), Color(0xFFFFF3B0), Color(0xFFFFD700),
              ]),
              boxShadow: const [BoxShadow(color: Color(0xFFFFD700), blurRadius: 36)],
            ),
            child: Center(
              child: Container(
                width: 110, height: 110, alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFF0B1020), shape: BoxShape.circle),
                child: const Text('★', style: TextStyle(color: Color(0xFFFFD700), fontSize: 64, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('${data.durationText.toUpperCase()} OF WORK', style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5,
          )),
          const SizedBox(height: 8),
          Expanded(
            child: Row(children: [
              Expanded(child: AspectRatio(aspectRatio: 0.8, child: ProgressShareImage(
                url: data.before.photoUrl,
                borderRadius: BorderRadius.circular(12),
              ))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 0.8, child: ProgressShareImage(
                url: data.after.photoUrl,
                borderRadius: BorderRadius.circular(12),
              ))),
            ]),
          ),
          const SizedBox(height: 12),
          Text('+${_xpFromStats(data)} XP · ${data.totalWorkouts} runs · ${data.currentStreak}-day streak',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (showWatermark) const ProgressShareWatermark(color: Colors.white70, compact: true),
        ]),
      ),
    );
  }

  int _xpFromStats(ProgressShareData d) => d.totalWorkouts * 50 + d.currentStreak * 10 + d.daysBetween;
}

// =============================================================================
// 12. Calendar Grid — month view with dots for logged workouts.
// =============================================================================

class CalendarGridTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const CalendarGridTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      backgroundColor: const Color(0xFF0E1116),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(data.durationText.toUpperCase(), style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3,
            )),
            const Spacer(),
            if (showWatermark) const ProgressShareWatermark(compact: true),
          ]),
          const Text('IN GREEN BOXES', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: AspectRatio(aspectRatio: 0.8, child: ProgressShareImage(url: data.before.photoUrl, borderRadius: BorderRadius.circular(8)))),
            const SizedBox(width: 8),
            Expanded(child: AspectRatio(aspectRatio: 0.8, child: ProgressShareImage(url: data.after.photoUrl, borderRadius: BorderRadius.circular(8)))),
          ]),
          const SizedBox(height: 14),
          Expanded(child: _buildCalendarHeat()),
          const SizedBox(height: 10),
          Row(children: [
            _legendDot(const Color(0xFF1E6F3E), 'logged'),
            const SizedBox(width: 12),
            _legendDot(const Color(0xFF2A3441), 'rest'),
            const Spacer(),
            Text('${data.totalWorkouts} total', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildCalendarHeat() {
    // Stable pseudo-random based on data so captures are deterministic.
    final rand = Random(data.totalWorkouts * 1000 + data.currentStreak);
    final totalCells = 7 * 14; // 14 weeks
    final loggedCount = min(totalCells, data.totalWorkouts + (data.currentStreak ~/ 2));
    final cells = List<bool>.generate(totalCells, (i) => false);
    var placed = 0;
    while (placed < loggedCount) {
      final idx = rand.nextInt(totalCells);
      if (!cells[idx]) { cells[idx] = true; placed++; }
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 14, mainAxisSpacing: 2, crossAxisSpacing: 2,
      ),
      itemCount: cells.length,
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(
          color: cells[i] ? const Color(0xFF1E6F3E) : const Color(0xFF2A3441),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String l) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 6),
    Text(l.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  ]);
}

// =============================================================================
// 13. Progress Bar — fitness-app style progress bar with percentage.
// =============================================================================

class ProgressBarTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const ProgressBarTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    // Progress = consistency score (streak / days between, capped at 100)
    final pct = data.daysBetween == 0 ? 1.0 : (data.currentStreak / data.daysBetween).clamp(0.0, 1.0);
    return ProgressTemplateCanvas(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0E2A1E), Color(0xFF1A4D37)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (showWatermark) const ProgressShareWatermark(compact: true),
            const Spacer(),
            const Text('PROGRESS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3)),
          ]),
          const SizedBox(height: 16),
          Text('${(pct * 100).round()}%', style: const TextStyle(
            color: Color(0xFFA8FF60), fontSize: 92, fontWeight: FontWeight.w900, height: 0.9, letterSpacing: -3,
          )),
          const Text('CONSISTENCY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3)),
          const SizedBox(height: 18),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFA8FF60), Color(0xFF00E5FF)]),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: const [BoxShadow(color: Color(0xFFA8FF60), blurRadius: 10)],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: Row(children: [
            Expanded(child: AspectRatio(aspectRatio: 0.8, child: ProgressShareImage(url: data.before.photoUrl, borderRadius: BorderRadius.circular(12)))),
            const SizedBox(width: 8),
            Expanded(child: AspectRatio(aspectRatio: 0.8, child: ProgressShareImage(url: data.after.photoUrl, borderRadius: BorderRadius.circular(12)))),
          ])),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _pbStat('${data.totalWorkouts}', 'WORKOUTS'),
            _pbStat('${data.currentStreak}', 'DAY STREAK'),
            _pbStat(data.durationText, 'JOURNEY'),
          ]),
        ]),
      ),
    );
  }

  Widget _pbStat(String v, String l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
    Text(l, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2)),
  ]);
}

// =============================================================================
// 14. Tape Measure — body measurement tape overlaying the after photo.
// =============================================================================

class TapeMeasureTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const TapeMeasureTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      backgroundColor: const Color(0xFFE8DCB8),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _TapeTicksPainter())),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0xFF2B2416),
                child: const Text('MEASURE UP', style: TextStyle(
                  color: Color(0xFFE8DCB8), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2,
                )),
              ),
              const Spacer(),
              if (showWatermark) const ProgressShareWatermark(color: Colors.black87, compact: true),
            ]),
            const SizedBox(height: 16),
            Text(data.weightDeltaKg != null ? data.weightLostText.toUpperCase() : data.durationText.toUpperCase(),
              style: const TextStyle(color: Color(0xFF2B2416), fontSize: 40, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1),
            ),
            const SizedBox(height: 4),
            const Text('IN THE BOOKS', style: TextStyle(color: Color(0xFF5A4A28), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
            const SizedBox(height: 20),
            Expanded(child: Row(children: [
              Expanded(child: AspectRatio(aspectRatio: 0.75, child: ProgressShareImage(url: data.before.photoUrl))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 0.75, child: ProgressShareImage(url: data.after.photoUrl))),
            ])),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2416),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(children: [
                _tapeMetric(data.beforeWeightKg, 'BEFORE', data.useKg),
                const Text('→', style: TextStyle(color: Color(0xFFE8DCB8), fontSize: 24, fontWeight: FontWeight.w900)),
                _tapeMetric(data.afterWeightKg, 'AFTER', data.useKg),
                const Spacer(),
                Text(data.durationText.toUpperCase(), style: const TextStyle(
                  color: Color(0xFFE8DCB8), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                )),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _tapeMetric(double? kg, String label, bool useKg) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFFE8DCB8), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      Text(
        kg == null ? '--' : '${useKg ? kg.toStringAsFixed(1) : (kg * 2.20462).toStringAsFixed(1)} ${useKg ? 'kg' : 'lb'}',
        style: const TextStyle(color: Color(0xFFFFE08A), fontSize: 16, fontWeight: FontWeight.w900),
      ),
    ]),
  );
}

class _TapeTicksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF2B2416).withValues(alpha: 0.15);
    for (double x = 0; x < size.width; x += 8) {
      final tall = (x / 8).floor() % 5 == 0;
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, tall ? 10 : 5), p);
      canvas.drawRect(Rect.fromLTWH(x, size.height - (tall ? 10 : 5), 1, tall ? 10 : 5), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// =============================================================================
// 15. Transformation Tuesday — TT meme format with arrow between photos.
// =============================================================================

class TransformationTuesdayTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const TransformationTuesdayTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    return ProgressTemplateCanvas(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0A0E1A), Color(0xFF1F2A44)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFE600), borderRadius: BorderRadius.circular(4)),
              child: const Text('#TRANSFORMATION\nTUESDAY', style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, height: 1.1,
              )),
            ),
            const Spacer(),
            if (showWatermark) const ProgressShareWatermark(compact: true),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: Row(children: [
                  Expanded(child: _ttPhoto(data.before.photoUrl, formatCompactDate(data.beforeDate), Colors.red.shade400)),
                  const SizedBox(width: 6),
                  Expanded(child: _ttPhoto(data.after.photoUrl, formatCompactDate(data.afterDate), const Color(0xFF00E676))),
                ]),
              ),
              Positioned.fill(
                child: Center(child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFFFE600), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 26),
                )),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Text('FROM "I\'LL START MONDAY"', style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2,
          )),
          const SizedBox(height: 2),
          Text('TO ${data.durationText.toUpperCase()} LATER'.toUpperCase(), style: const TextStyle(
            color: Color(0xFFFFE600), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1,
          )),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _ttChip('${data.totalWorkouts} WORKOUTS'),
            const SizedBox(width: 8),
            _ttChip('${data.currentStreak}D STREAK'),
            if (data.weightDeltaKg != null) ...[
              const SizedBox(width: 8),
              _ttChip(data.weightLostText.toUpperCase()),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _ttPhoto(String url, String caption, Color c) => Container(
    decoration: BoxDecoration(border: Border.all(color: c, width: 2), borderRadius: BorderRadius.circular(8)),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(children: [
        Positioned.fill(child: ProgressShareImage(url: url)),
        Positioned(
          left: 6, bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: c,
            child: Text(caption, style: const TextStyle(
              color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900,
            )),
          ),
        ),
      ]),
    ),
  );

  Widget _ttChip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white24),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
  );
}

// =============================================================================
// 16. Timeline Ruler — horizontal weeks ruler with checkpoints.
// =============================================================================

class TimelineRulerTemplate extends StatelessWidget {
  final ProgressShareData data;
  final bool showWatermark;
  const TimelineRulerTemplate({super.key, required this.data, this.showWatermark = true});

  @override
  Widget build(BuildContext context) {
    final weeks = max(2, (data.daysBetween / 7).ceil());
    return ProgressTemplateCanvas(
      backgroundColor: const Color(0xFF0A0B0E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Text('TIMELINE', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const Spacer(),
            Text('W1 → W$weeks', style: const TextStyle(
              color: Color(0xFFFF8A00), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2,
            )),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _rulerCaption('WEEK 1', formatCompactDate(data.beforeDate)),
                const SizedBox(height: 6),
                AspectRatio(aspectRatio: 1, child: ProgressShareImage(url: data.before.photoUrl, borderRadius: BorderRadius.circular(8))),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _rulerCaption('WEEK $weeks', formatCompactDate(data.afterDate), align: TextAlign.right),
                const SizedBox(height: 6),
                AspectRatio(aspectRatio: 1, child: ProgressShareImage(url: data.after.photoUrl, borderRadius: BorderRadius.circular(8))),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          _rulerBar(weeks),
          const SizedBox(height: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _checkpoint('STARTED', 'Fresh on day 1.'),
            _checkpoint('WEEK ${(weeks / 2).ceil()}', 'Habits stuck. Hit ${data.currentStreak}-day streak.'),
            _checkpoint('TODAY', '${data.totalWorkouts} workouts logged. Keep going.'),
          ])),
          if (showWatermark) const Center(child: ProgressShareWatermark(compact: true)),
        ]),
      ),
    );
  }

  Widget _rulerCaption(String w, String d, {TextAlign align = TextAlign.left}) => Column(
    crossAxisAlignment: align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(w, style: const TextStyle(color: Color(0xFFFF8A00), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
      Text(d, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
    ],
  );

  Widget _rulerBar(int weeks) => SizedBox(
    height: 28,
    child: LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      return Stack(children: [
        Positioned(
          left: 0, right: 0, top: 13,
          child: Container(height: 2, color: Colors.white12),
        ),
        ...List.generate(weeks, (i) {
          final x = (i / (weeks - 1)) * (w - 6);
          return Positioned(
            left: x, top: 10,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFFFF8A00), shape: BoxShape.circle),
            ),
          );
        }),
      ]);
    }),
  );

  Widget _checkpoint(String label, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 6, right: 10), decoration: const BoxDecoration(color: Color(0xFFFF8A00), shape: BoxShape.circle)),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFFFF8A00), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
      ])),
    ]),
  );
}
