import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// ChatBubble — mocked iMessage screenshot. Top "FitWiz" header, gray
/// reply with workout summary, accent-colored sent bubble with the
/// celebration text, tiny "Delivered" timestamp.
class ChatBubbleTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const ChatBubbleTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  String _summary(Shareable d) {
    final hero = shareableHeroString(d);
    final unit = shareableHeroUnit(d);
    if (hero == '—') return d.title;
    if (unit.isEmpty) return '${d.title} · $hero';
    return '${d.title} · $hero $unit';
  }

  String _celebration(Shareable d) {
    final hl = d.highlights.where((h) => h.isPopulated).toList();
    if (hl.isEmpty) return 'Boom. Done. 🎯';
    final h = hl.first;
    return '${h.value} ${h.label.toLowerCase()} — let\'s gooo';
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final name = (data.userDisplayName ?? 'You').trim();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF000000), Color(0xFF0A0A0A)],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 56),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.chevron_left_rounded,
                    color: accent, size: 24 * mul),
                const SizedBox(width: 4),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent,
                        Color.lerp(accent, Colors.white, 0.4)!,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FitWiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15 * mul,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'iMessage',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11 * mul,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.video_call_outlined,
                    color: accent, size: 20 * mul),
              ],
            ),
            const Spacer(),
            // Received bubble (FitWiz → user).
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26282E),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    _summary(data),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * mul,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Sent bubble (user celebrating).
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    _celebration(data),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16 * mul,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Delivered',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10 * mul,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'iMessage to $name',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13 * mul,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.mic_none_rounded,
                      color: accent, size: 18 * mul),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (showWatermark)
              FitWizWatermark(
                textColor: Colors.white,
                fontSize: 12 * mul,
              ),
          ],
        ),
      ),
    );
  }
}
