import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// BoardingPass — airline boarding-pass aesthetic. Cream paper background,
/// dashed perforation splitting main body + stub, "FROM: Last Workout /
/// TO: Next Goal", flight number = workout count, gate = day number,
/// barcode at the bottom.
class BoardingPassTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const BoardingPassTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const _cream = Color(0xFFF6F1E2);
  static const _ink = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final hl = data.highlights.where((h) => h.isPopulated).toList();
    final flightNumber = (data.heroValue?.round() ?? hl.length).toString();
    final now = DateTime.now();
    final hr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF111014), Color(0xFF050507)],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AspectRatio(
            aspectRatio: 1.65,
            child: Container(
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Main pass body.
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'FW',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Times New Roman',
                                    fontSize: 14 * mul,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'FITWIZ AIRLINES',
                                style: TextStyle(
                                  color: _ink,
                                  fontFamily: 'Times New Roman',
                                  fontSize: 11 * mul,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'BOARDING PASS',
                                style: TextStyle(
                                  color: _ink.withValues(alpha: 0.6),
                                  fontSize: 9 * mul,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _route('FROM', 'LAST', mul),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.airplanemode_active_rounded,
                                    color: accent, size: 22 * mul),
                              ),
                              Expanded(
                                child: _route('TO', 'NEXT', mul),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 15 * mul,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _info('FLIGHT', 'FW $flightNumber', mul),
                              _info('GATE', '${now.day}', mul),
                              _info('BOARDING', hr, mul),
                            ],
                          ),
                          const Spacer(),
                          // Barcode.
                          SizedBox(
                            height: 32,
                            child: CustomPaint(
                              painter: _BarcodePainter(),
                              size: const Size(double.infinity, 32),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                (data.userDisplayName ?? 'PASSENGER')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: _ink.withValues(alpha: 0.7),
                                  fontSize: 10 * mul,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const Spacer(),
                              if (showWatermark)
                                AppWatermark(
                                  textColor: _ink,
                                  fontSize: 10 * mul,
                                  iconSize: 14,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Perforation.
                  CustomPaint(
                    painter: _PerforationPainter(),
                    size: const Size(2, double.infinity),
                  ),
                  // Stub.
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PASS',
                            style: TextStyle(
                              color: accent,
                              fontFamily: 'Times New Roman',
                              fontSize: 11 * mul,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'FW $flightNumber',
                            style: TextStyle(
                              color: _ink,
                              fontFamily: 'Times New Roman',
                              fontSize: 24 * mul,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _info('SEAT', '${now.day}A', mul),
                          _info('GATE', '${now.day}', mul),
                          const Spacer(),
                          Text(
                            data.periodLabel.toUpperCase(),
                            style: TextStyle(
                              color: _ink.withValues(alpha: 0.6),
                              fontSize: 9 * mul,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _route(String label, String value, double mul) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _ink.withValues(alpha: 0.6),
            fontSize: 9 * mul,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _ink,
            fontSize: 30 * mul,
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _info(String label, String value, double mul) {
    return Padding(
      padding: const EdgeInsets.only(right: 14, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _ink.withValues(alpha: 0.55),
              fontSize: 8 * mul,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _ink,
              fontFamily: 'Times New Roman',
              fontSize: 14 * mul,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1A1A);
    var x = 0.0;
    var seed = 7;
    while (x < size.width) {
      final w = (seed % 5) + 1.0;
      paint.color = (seed % 3 == 0)
          ? const Color(0xFF1A1A1A).withValues(alpha: 0.85)
          : const Color(0xFF1A1A1A);
      if (seed % 4 != 0) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      }
      x += w + 1.5;
      seed = (seed * 17 + 3) % 31;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    for (double y = 4; y < size.height - 4; y += 8) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
