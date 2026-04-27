import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// Receipt — thermal-receipt style listing of highlights as line items,
/// hero shown as the "TOTAL" at the bottom. Reads as a transaction record.
class ReceiptTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const ReceiptTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final highlights = data.highlights.toList();
    final extras = data.subMetrics.toList();
    final lines = [...highlights, ...extras].take(8).toList();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [
        Color(0xFF0F0F10),
        Color(0xFF1A1A1C),
        Color(0xFF0F0F10),
      ],
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F2E8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  '— ${data.title.toUpperCase()} —',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  data.periodLabel.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11 * mul,
                    color: const Color(0xFF555555),
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _Dashed(),
              const SizedBox(height: 8),
              for (final m in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12 * mul,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        m.value,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 13 * mul,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              const _Dashed(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14 * mul,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 1.4,
                    ),
                  ),
                  Text(
                    '${shareableHeroString(data)} ${shareableHeroUnit(data)}'.trim(),
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 18 * mul,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: showWatermark
                    ? AppWatermark(
                        textColor: const Color(0xFF1A1A1A),
                        iconSize: 18,
                        fontSize: 11,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedPainter(),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
