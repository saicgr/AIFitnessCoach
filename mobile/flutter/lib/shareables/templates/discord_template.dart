import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// Discord embed style — orange left bar, server avatar (real Zealova
/// app icon), header, body, field grid. Mimics the rich-embed format
/// communities post in Discord servers.
class DiscordTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const DiscordTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const Color _bg = Color(0xFF36393F);

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF202225), Color(0xFF202225), Color(0xFF202225)],
      child: Padding(
        padding: _padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 6, color: AppColors.orange),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Server header — real Zealova app icon.
                            Row(
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    'assets/images/app_icon.png',
                                    width: 28 * mul,
                                    height: 28 * mul,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Zealova',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18 * mul,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              data.title.isEmpty ? 'Workout logged' : data.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26 * mul,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: 22,
                              runSpacing: 14,
                              children: [
                                for (final m in data.highlights.take(4))
                                  _field(m.label, m.value, mul),
                                if (data.subMetrics.isNotEmpty)
                                  for (final m in data.subMetrics.take(2))
                                    _field(m.label, m.value, mul),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Powered by Zealova',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12 * mul,
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
            if (showWatermark) ...[
              const SizedBox(height: 24),
              const AppWatermark(textColor: Colors.white70),
            ],
          ],
        ),
      ),
    );
  }

  EdgeInsets get _padding {
    switch (data.aspect) {
      case ShareableAspect.square:
        return const EdgeInsets.all(36);
      case ShareableAspect.portrait:
        return const EdgeInsets.fromLTRB(40, 56, 40, 40);
      case ShareableAspect.story:
        return const EdgeInsets.fromLTRB(40, 88, 40, 56);
    }
  }

  Widget _field(String k, String v, double mul) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            k.toUpperCase(),
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12 * mul,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            v,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18 * mul,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}
