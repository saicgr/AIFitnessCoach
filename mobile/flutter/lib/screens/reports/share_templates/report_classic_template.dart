import 'package:flutter/material.dart';

import '../../workout/widgets/share_templates/_share_common.dart';
import '_report_common.dart';

/// Classic — accent-tinted dark gradient with a big hero number and up to
/// three sub-stats. This is the universal default template and therefore
/// has zero reliance on report-specific data beyond the generic payload.
class ReportClassicTemplate extends StatelessWidget {
  final ReportShareData data;
  final bool showWatermark;

  const ReportClassicTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final hero = heroMetricFor(data);
    final unit = heroUnitFor(data);
    final subs = subStatsFor(data);
    final name = (data.userDisplayName ?? 'Lifter').toUpperCase();

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: accentGradient(data.accentColor),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip — period + report name.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShareTrackedCaps(
                  data.periodLabel,
                  size: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                ShareTrackedCaps(
                  data.title,
                  size: 11,
                  color: data.accentColor,
                ),
              ],
            ),
            const Spacer(),
            // Hero number.
            ShareHeroNumber(
              value: hero,
              unit: unit.isEmpty ? null : unit,
              size: 160,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            // Sub-stats row — up to 3. Rendered with "—" placeholders when
            // the highlights list is empty so the strip still reads.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (i) {
                final h = i < subs.length ? subs[i] : null;
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShareTrackedCaps(
                        h?.label ?? '—',
                        size: 9,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 2.2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        h?.value ?? '—',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShareTrackedCaps(
                  'ZEALOVA REPORT',
                  size: 9,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                ShareWatermarkBadge(enabled: showWatermark),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
