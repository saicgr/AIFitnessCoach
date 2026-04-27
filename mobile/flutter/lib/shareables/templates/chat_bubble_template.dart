import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// ChatBubble — mocked iMessage screenshot. Top "Zealova" header, gray
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

  /// iMessage's signature send-bubble blue. We use this regardless of the
  /// shareable's accent so the bubble always reads as a real iMessage —
  /// using a low-chroma user accent (e.g. white) collapsed into an
  /// unrecognizable white blob in the previous version.
  static const Color _iMessageBlue = Color(0xFF0B84FF);
  /// iOS dark-mode received-bubble grey.
  static const Color _receivedGrey = Color(0xFF26282E);

  String _firstHighlight(Shareable d) {
    final hl = d.highlights.where((h) => h.isPopulated).toList();
    if (hl.length < 2) return '';
    return hl[1].value;
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    // Status-bar style timestamp — locked to a plausible time so the mock
    // reads as a real screenshot rather than a stale render.
    final now = DateTime.now();
    final hour12 = ((now.hour + 11) % 12) + 1;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final timestamp =
        '$hour12:${now.minute.toString().padLeft(2, '0')} $ampm';

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF000000), Color(0xFF0A0A0A)],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 48),
        child: Column(
          children: [
            // iOS-style status bar.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    timestamp,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14 * mul,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.signal_cellular_alt_rounded,
                      color: Colors.white, size: 14 * mul),
                  const SizedBox(width: 4),
                  Icon(Icons.wifi_rounded,
                      color: Colors.white, size: 14 * mul),
                  const SizedBox(width: 4),
                  Container(
                    width: 22 * mul,
                    height: 11 * mul,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Centered contact header — back chevron, vertical avatar +
            // name stack, FaceTime icon.
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Icon(Icons.chevron_left_rounded,
                        color: _iMessageBlue, size: 28 * mul),
                    Positioned(
                      left: 18,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _iMessageBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '7',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10 * mul,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 44 * mul,
                        height: 44 * mul,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent,
                              Color.lerp(accent, Colors.black, 0.35)!,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(Icons.bolt_rounded,
                              color: Colors.white, size: 22 * mul),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Branding.appName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12 * mul,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.white.withValues(alpha: 0.55),
                              size: 14 * mul),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.videocam_rounded,
                    color: _iMessageBlue, size: 24 * mul),
              ],
            ),
            const SizedBox(height: 8),
            // Subtle date divider, like real iMessage.
            Text(
              'Today ${_dateLabel(now)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11 * mul,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            // Received bubble cluster (Zealova → user). Two stacked bubbles
            // so it reads as a real conversation, with tail on the bottom.
            _ReceivedBubble(
              text: _summary(data),
              tail: false,
              fontSize: 16 * mul,
              maxWidth: 320,
            ),
            const SizedBox(height: 3),
            _ReceivedBubble(
              text: _firstHighlight(data).isEmpty
                  ? 'You crushed it. Save this one.'
                  : 'New ${_firstHighlight(data)} on the board 🔥',
              tail: true,
              fontSize: 16 * mul,
              maxWidth: 320,
            ),
            const SizedBox(height: 14),
            // Sent bubble (user celebrating) — tailed iMessage blue.
            _SentBubble(
              text: _celebration(data),
              color: _iMessageBlue,
              fontSize: 16 * mul,
              maxWidth: 320,
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerRight,
              child: _ReadReceipt(),
            ),
            const Spacer(),
            // iMessage compose row — pill input with paperclip + voice.
            Row(
              children: [
                Container(
                  width: 32 * mul,
                  height: 32 * mul,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 20 * mul),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'iMessage',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14 * mul,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.mic_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 18 * mul),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (showWatermark)
              AppWatermark(
                textColor: Colors.white,
                fontSize: 12 * mul,
              ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) {
    final hour12 = ((d.hour + 11) % 12) + 1;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _ReceivedBubble extends StatelessWidget {
  final String text;
  final bool tail;
  final double fontSize;
  final double maxWidth;
  const _ReceivedBubble({
    required this.text,
    required this.tail,
    required this.fontSize,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: ChatBubbleTemplate._receivedGrey,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(tail ? 18 : 6),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(tail ? 4 : 6),
              bottomRight: const Radius.circular(18),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _SentBubble extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double maxWidth;
  const _SentBubble({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadReceipt extends StatelessWidget {
  const _ReadReceipt();
  @override
  Widget build(BuildContext context) {
    return Text(
      'Read',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
