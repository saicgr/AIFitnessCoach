import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/safe_num.dart';
import '../../../data/models/trophy.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// IN PROGRESS — Signature hairline rows with small disciplined conic
/// progress arcs (the one place a ring earns its keep). Each row: a tiny
/// rarity-tinted arc + emoji, the trophy name + reset hint, and a mono count.
class InProgressStrip extends ConsumerWidget {
  final List<TrophyProgress> trophies;

  const InProgressStrip({super.key, required this.trophies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (trophies.isEmpty) {
      return const _EmptyInProgress();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (int i = 0; i < trophies.length; i++)
            _InProgressRow(
              progress: trophies[i],
              isLast: i == trophies.length - 1,
            ),
        ],
      ),
    );
  }
}


class _InProgressRow extends StatelessWidget {
  final TrophyProgress progress;
  final bool isLast;

  const _InProgressRow({required this.progress, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final metal = progress.trophy.trophyTier.primaryColor;
    final pct = (progress.progressFraction).clamp(0.0, 1.0);

    return InkWell(
      onTap: () => HapticService.light(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.hairline)),
              ),
        child: Row(
          children: [
            // conic arc + emoji + mono percent
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: const Size(38, 38),
                    painter: _ArcPainter(
                      fraction: pct,
                      color: metal,
                      track: AppColors.hairlineStrong,
                    ),
                  ),
                  Text(progress.trophy.icon,
                      style: const TextStyle(fontSize: 15)),
                  PositionedDirectional(
                    end: -4,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      color: tc.background,
                      child: Text(
                        '${safePercent(pct * 100)}%',
                        style: ZType.data(7, color: tc.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    progress.trophy.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: tc.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    progress.trophy.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZType.lbl(8.5, color: tc.textMuted, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${safePercent(pct * 100)}%',
              style: ZType.data(11, color: tc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}


class _ArcPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color track;

  _ArcPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction > 0) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}


class _EmptyInProgress extends StatelessWidget {
  const _EmptyInProgress();

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Text(
        AppLocalizations.of(context).inProgressStripLogAWorkoutTo,
        style: TextStyle(color: tc.textMuted, fontSize: 13, height: 1.35),
      ),
    );
  }
}
