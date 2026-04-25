import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';
import '../widgets/shareable_hero_number.dart';

/// Trading Card — Pokemon-card style. Shows the user's avatar/initials, the
/// hero stat in a bordered window, and 2 highlights as "moves".
class TradingCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const TradingCardTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: accent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent,
                Color.lerp(accent, Colors.black, 0.3)!,
                Color.lerp(accent, Colors.black, 0.6)!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    backgroundImage: (data.userAvatarUrl != null &&
                            data.userAvatarUrl!.isNotEmpty)
                        ? NetworkImage(data.userAvatarUrl!)
                        : null,
                    child: (data.userAvatarUrl == null ||
                            data.userAvatarUrl!.isEmpty)
                        ? Text(
                            _initials(data.userDisplayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.userDisplayName ?? 'Lifter',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * mul,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          data.title.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11 * mul,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    data.periodLabel.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: ShareableHeroNumber(
                    data: data,
                    size: 72,
                    unitSize: 16,
                    stacked: false,
                    color: Colors.white,
                    unitColor: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...data.highlights.take(3).map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.flash_on_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12 * mul,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            h.value,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13 * mul,
                              fontWeight: FontWeight.w900,
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
                  child: FitWizWatermark(
                    textColor: Colors.white,
                    iconSize: 18,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    final t = (name ?? '').trim();
    if (t.isEmpty) return 'YOU';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
