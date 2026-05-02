import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// 1RM estimate — clean white card with the primary lift's estimated
/// 1-rep max in massive type, plus a stack of secondary 1RMs underneath.
/// Pulls primary from `heroValue / heroUnit` and secondaries from
/// `subMetrics`.
class OneRmTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const OneRmTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final hero = data.heroValue == null
        ? '—'
        : '${data.heroPrefix ?? ''}${data.heroValue}${data.heroSuffix ?? ''}';
    final unit = data.heroUnitSingular;

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFFF8FAFC), Color(0xFFF8FAFC), Color(0xFFF8FAFC)],
      child: Padding(
        padding: _padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1RM ESTIMATE',
              style: TextStyle(
                fontSize: 14 * mul,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: AppColors.orange,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16 * mul,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hero,
                        style: TextStyle(
                          fontSize: 96 * mul,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1,
                          letterSpacing: -3,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 14 * mul),
                          child: Text(
                            ' ${unit.toLowerCase()}',
                            style: TextStyle(
                              fontSize: 22 * mul,
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (data.periodLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Epley · ${data.periodLabel}',
                      style: TextStyle(
                        fontSize: 13 * mul,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...data.subMetrics.take(4).map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              m.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12 * mul,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              m.value,
                              style: TextStyle(
                                fontSize: 16 * mul,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (showWatermark) ...[
                  const SizedBox(height: 16),
                  const AppWatermark(textColor: Colors.black54),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  EdgeInsets get _padding {
    switch (data.aspect) {
      case ShareableAspect.square:
        return const EdgeInsets.all(40);
      case ShareableAspect.portrait:
        return const EdgeInsets.fromLTRB(48, 56, 48, 48);
      case ShareableAspect.story:
        return const EdgeInsets.fromLTRB(48, 96, 48, 64);
    }
  }
}
