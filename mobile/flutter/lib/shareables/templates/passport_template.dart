import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Passport stamp — navy cover + gold lettering, white interior page
/// with a red ENTERED stamp. Each workout = a new stamp in the user's
/// gains passport.
class PassportTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PassportTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _gold = Color(0xFFFBBF24);
  static const Color _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final stampNumber = _stampNumber();
    final entryHighlight = data.highlights.isNotEmpty
        ? data.highlights.first.value
        : data.heroValue?.toString() ?? '';
    final firstName = (data.userDisplayName ?? '').trim().split(' ').first;

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [_navy, _navy, _navy],
      child: Padding(
        padding: _padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🌍', style: TextStyle(fontSize: 36 * mul)),
                Text(
                  'PASSPORT',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 22 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            // White interior page.
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STAMP $stampNumber',
                    style: TextStyle(
                      fontSize: 12 * mul,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    Branding.appName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 32 * mul,
                      fontWeight: FontWeight.w900,
                      color: _navy,
                    ),
                  ),
                  if (firstName.isNotEmpty)
                    Text(
                      'TRAVELER · $firstName',
                      style: TextStyle(
                        fontSize: 11 * mul,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 14 * mul,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (entryHighlight.isNotEmpty)
                    Text(
                      entryHighlight,
                      style: TextStyle(
                        fontSize: 12 * mul,
                        color: Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Stamp.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: _red, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ENTERED',
                      style: TextStyle(
                        color: _red,
                        fontSize: 13 * mul,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'GAINS · ${data.periodLabel.toUpperCase()}',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 12 * mul,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (showWatermark) ...[
                  const SizedBox(height: 12),
                  const AppWatermark(textColor: Colors.white60),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pulls a stable "stamp number" — uses any numeric subMetric (like
  /// "Workout #14"), else falls back to the hero value if it's an int.
  String _stampNumber() {
    for (final m in data.subMetrics) {
      final n = int.tryParse(m.value.replaceAll(RegExp(r'[^0-9]'), ''));
      if (n != null && n > 0) return '#$n';
    }
    final h = data.heroValue;
    if (h is int) return '#$h';
    if (h is num && h == h.roundToDouble()) return '#${h.toInt()}';
    return '·';
  }

  EdgeInsets get _padding {
    switch (data.aspect) {
      case ShareableAspect.square:
        return const EdgeInsets.all(40);
      case ShareableAspect.portrait:
        return const EdgeInsets.fromLTRB(48, 60, 48, 48);
      case ShareableAspect.story:
        return const EdgeInsets.fromLTRB(48, 96, 48, 64);
    }
  }
}
