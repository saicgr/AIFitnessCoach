import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/trophy.dart';
import '../../../data/models/wrapped_data.dart';
import '../../../data/providers/xp_provider.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Wrapped slide showing the trophies earned in the Wrapped period.
/// Shares the same sunburst-on-black visual language as the app-open
/// celebration ceremony so the two surfaces feel like one flow.
///
/// Falls back to a "no new badges yet" card if the period has no earned
/// trophies — still keeps the visual tone so Wrapped doesn't break mid-swipe.
class WrappedTrophiesCard extends ConsumerWidget {
  final WrappedData data;
  final bool showWatermark;

  const WrappedTrophiesCard({
    super.key,
    required this.data,
    this.showWatermark = false,
  });

  DateTimeRange? _periodRange() {
    // periodKey format is "YYYY-MM" for monthly or "YYYY-WNN" for weekly.
    final raw = data.periodKey;
    try {
      if (raw.contains('-W')) {
        // Weekly — parse year + ISO week, span 7 days starting Monday.
        final parts = raw.split('-W');
        final year = int.parse(parts[0]);
        final week = int.parse(parts[1]);
        final jan4 = DateTime(year, 1, 4);
        final weekday = jan4.weekday;
        final mondayOfWeek1 = jan4.subtract(Duration(days: weekday - 1));
        final start = mondayOfWeek1.add(Duration(days: (week - 1) * 7));
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      } else {
        // Monthly — YYYY-MM
        final parts = raw.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final start = DateTime(year, month);
        final end = DateTime(year, month + 1);
        return DateTimeRange(start: start, end: end);
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = ref.watch(earnedTrophiesProvider);
    final range = _periodRange();

    final inPeriod = range == null
        ? earned.take(3).toList()
        : earned.where((t) {
            final at = t.earnedAt;
            if (at == null) return false;
            return at.isAfter(range.start) && at.isBefore(range.end);
          }).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF1F2937), Colors.black],
          radius: 1.1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR BADGES',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              inPeriod.isEmpty
                  ? 'No new badges this period — yet.'
                  : inPeriod.length == 1
                      ? '1 new badge this period'
                      : '${inPeriod.length} new badges this period',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: inPeriod.isEmpty
                  ? const _WrappedTrophiesEmpty()
                  : _WrappedTrophiesStack(trophies: inPeriod.take(6).toList()),
            ),
            if (showWatermark)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    '${Branding.appName} Wrapped',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _WrappedTrophiesStack extends StatelessWidget {
  final List<TrophyProgress> trophies;
  const _WrappedTrophiesStack({required this.trophies});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.vertical,
      itemCount: trophies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final t = trophies[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CustomPaint(
                  painter: _MiniSunburst(color: const Color(0xFFFBBF24)),
                  child: Center(
                    child: Text(
                      t.trophy.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.trophy.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (t.trophy.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        t.trophy.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _WrappedTrophiesEmpty extends StatelessWidget {
  const _WrappedTrophiesEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Keep showing up — badges unlock as you hit milestones.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}


class _MiniSunburst extends CustomPainter {
  final Color color;
  _MiniSunburst({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final p = Paint()..color = color.withValues(alpha: 0.45);
    const rayCount = 14;
    for (int i = 0; i < rayCount; i++) {
      final theta = (2 * math.pi / rayCount) * i;
      final half = (math.pi / rayCount) * 0.35;
      final path = Path()
        ..moveTo(
          center.dx + r * 0.35 * math.cos(theta - half),
          center.dy + r * 0.35 * math.sin(theta - half),
        )
        ..lineTo(
          center.dx + r * math.cos(theta),
          center.dy + r * math.sin(theta),
        )
        ..lineTo(
          center.dx + r * 0.35 * math.cos(theta + half),
          center.dy + r * 0.35 * math.sin(theta + half),
        )
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSunburst old) => old.color != color;
}
