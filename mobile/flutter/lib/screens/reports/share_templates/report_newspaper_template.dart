import 'package:flutter/material.dart';

import '../../workout/widgets/share_templates/_share_common.dart';
import '_report_common.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Newspaper — cream-paper "THE FITWIZ TIMES" masthead with a serif
/// headline built from the user's name + hero value + period label. Short
/// body copy is stitched together from top highlights so the sheet reads
/// like a news column even on data-sparse reports.
class ReportNewspaperTemplate extends StatelessWidget {
  final ReportShareData data;
  final bool showWatermark;

  const ReportNewspaperTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final hero = heroMetricFor(data);
    final unit = heroUnitFor(data);
    final name = data.userDisplayName ?? 'A local lifter';
    final headline = _headline(name, hero, unit, data);
    final body = _body(data);

    return RepaintBoundary(
      child: Container(
        // Warm newsprint background.
        color: const Color(0xFFF4EDDC),
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Masthead
            Container(
              padding: const EdgeInsets.only(bottom: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data.periodLabel,
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'THE FITWIZ TIMES',
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    'NO. 01',
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Divider(
              color: Color(0xFF1A1A1A),
              thickness: 1,
              height: 4,
            ),
            const SizedBox(height: 18),
            const Text(
              'EXCLUSIVE REPORT',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF8B0000),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              headline,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.05,
                color: Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '— ${data.title.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    color: Color(0xFF333333),
                  ),
                ),
                if (showWatermark)
                  const ShareWatermarkBadge(color: Color(0xFF333333)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Headline recipe — inserts the hero value and unit with light variation.
  // Keeps it readable when any component is missing.
  String _headline(String name, String hero, String unit, ReportShareData d) {
    final n = name.trim().isEmpty ? 'A local lifter' : name;
    final u = unit.isEmpty ? '' : ' $unit';
    final period = d.periodLabel.trim().isEmpty ? 'this month' : d.periodLabel;
    return '$n logs $hero$u in $period';
  }

  // Stitches body copy from the first few highlights so the article is
  // grounded in real data rather than boilerplate.
  String _body(ReportShareData d) {
    if (d.highlights.isEmpty) {
      return 'Numbers climb. Discipline compounds. ${Branding.appName} captured the receipts '
          'so every rep, every minute, every win shows up exactly where it '
          'belongs — in the record.';
    }
    final parts = d.highlights.take(3).map((h) {
      return '${h.label.toLowerCase()}: ${h.value}';
    }).join('. ');
    return 'Reporters confirm: $parts. The trend continues, and ${Branding.appName} keeps '
        'the receipts.';
  }
}
