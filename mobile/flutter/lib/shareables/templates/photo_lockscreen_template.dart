import 'dart:ui';

import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/photo_backdrop.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// PhotoLockscreen — iOS-lockscreen mockup. User photo as wallpaper, status
/// bar at top, big stylized clock, then a "Zealova" widget pinned below
/// showing the workout summary as a frosted-glass card. Distinct from
/// Widget template (which renders a single iOS-widget card on a solid
/// canvas) because this puts your photo as the wallpaper.
class PhotoLockscreenTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PhotoLockscreenTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final now = DateTime.now();
    final hr = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final time = '$hr:${now.minute.toString().padLeft(2, '0')}';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final dateLine =
        '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    final hl = data.highlights.where((h) => h.isPopulated).take(3).toList();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF000000), Color(0xFF000000)],
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhotoBackdrop(
            path: data.customPhotoPath,
            fallbackGradient: [
              Color.lerp(accent, Colors.black, 0.35)!,
              Color.lerp(accent, Colors.black, 0.75)!,
            ],
            topScrim: 0.18,
            bottomScrim: 0.30,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status bar.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * mul,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_alt_rounded,
                            color: Colors.white, size: 14 * mul),
                        const SizedBox(width: 4),
                        Icon(Icons.wifi_rounded,
                            color: Colors.white, size: 14 * mul),
                        const SizedBox(width: 4),
                        Container(
                          width: 22,
                          height: 11,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.78,
                              child: Container(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Icon(Icons.lock_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 16 * mul),
                const SizedBox(height: 18),
                Text(
                  dateLine,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * mul,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    shadows: const [
                      Shadow(blurRadius: 10, color: Colors.black87),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: data.aspect == ShareableAspect.story
                        ? 144
                        : 110,
                    fontWeight: FontWeight.w300,
                    height: 0.95,
                    letterSpacing: -4,
                    shadows: const [
                      Shadow(blurRadius: 18, color: Colors.black87),
                    ],
                  ),
                ),
                const Spacer(),
                // Zealova widget card.
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    accent,
                                    Color.lerp(accent, Colors.white, 0.4)!,
                                  ]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.bolt_rounded,
                                    color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${Branding.appName}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13 * mul,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                data.periodLabel.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10 * mul,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18 * mul,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (var i = 0; i < hl.length; i++) ...[
                                Expanded(
                                  child: _widgetStat(hl[i], mul, accent),
                                ),
                                if (i < hl.length - 1)
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color:
                                        Colors.white.withValues(alpha: 0.18),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (showWatermark)
                  AppWatermark(
                    textColor: Colors.white,
                    fontSize: 11 * mul,
                    iconSize: 16,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _widgetStat(ShareableMetric m, double mul, Color accent) {
    return Column(
      children: [
        Text(
          m.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16 * mul,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          m.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9 * mul,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
