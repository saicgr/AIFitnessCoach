import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// Weekly Report — receipt-card style with a 7-day bar chart driven by
/// `subMetrics` (one entry per weekday, value parses as 0/1 for hit/miss).
class WeeklyReportTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WeeklyReportTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final week = data.subMetrics.take(7).toList();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [
        Color(0xFF0E1226),
        Color(0xFF11193D),
        Color(0xFF050616),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 56, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WEEKLY REPORT',
              style: TextStyle(
                color: data.accentColor,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.periodLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13 * mul,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(week.length, (i) {
                  final m = week[i];
                  final filled =
                      double.tryParse(m.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                  final h = (filled.clamp(0, 1) * 220) + 30;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: h.toDouble(),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  data.accentColor,
                                  Color.lerp(data.accentColor, Colors.white,
                                      0.3)!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m.label.substring(0, m.label.length.clamp(0, 1)),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            ...data.highlights.take(3).map(
                  (h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            h.label.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        Text(
                          h.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            if (showWatermark)
              Align(
                alignment: Alignment.centerRight,
                child: AppWatermark(textColor: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
