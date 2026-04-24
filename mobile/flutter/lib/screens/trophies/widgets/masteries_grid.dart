import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/masteries_provider.dart';

/// 3-column grid of levelled mastery badges (Steps Lv.6 etc.). Each cell
/// renders a hex-shaped badge with the mastery icon, colour-tiered by
/// current level, and a subtitle showing the user's level.
class MasteriesGrid extends StatelessWidget {
  final List<MasteryEntry> entries;
  final bool loading;

  const MasteriesGrid({
    super.key,
    required this.entries,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return _LoadingGrid(isDark: isDark);
    }
    if (entries.isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) => _MasteryCell(
        entry: entries[i],
        isDark: isDark,
      ),
    );
  }
}


class _MasteryCell extends StatelessWidget {
  final MasteryEntry entry;
  final bool isDark;

  const _MasteryCell({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CustomPaint(
              painter: _HexBadgePainter(
                palette: _paletteForLevel(entry.level),
              ),
              child: Center(
                child: Icon(
                  _iconFor(entry.icon),
                  color: _paletteForLevel(entry.level).glyph,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : AppColorsLight.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lv.${entry.level}',
              style: TextStyle(
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'directions_run':
        return Icons.directions_run;
      case 'timer_outlined':
        return Icons.timer_outlined;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'terrain':
        return Icons.terrain;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}


class _HexPalette {
  final Color rim;
  final Color plateLight;
  final Color plateDark;
  final Color glyph;
  const _HexPalette(this.rim, this.plateLight, this.plateDark, this.glyph);
}


_HexPalette _paletteForLevel(int level) {
  if (level >= 6) {
    // Gold
    return const _HexPalette(
      Color(0xFFB45309),
      Color(0xFFFEF3C7),
      Color(0xFFF59E0B),
      Color(0xFF78350F),
    );
  }
  if (level >= 3) {
    // Silver
    return const _HexPalette(
      Color(0xFF6B7280),
      Color(0xFFF3F4F6),
      Color(0xFFD1D5DB),
      Color(0xFF1F2937),
    );
  }
  if (level >= 1) {
    // Bronze
    return const _HexPalette(
      Color(0xFF92400E),
      Color(0xFFFDE68A),
      Color(0xFFB45309),
      Color(0xFF451A03),
    );
  }
  // Lv 0 — greyed / not yet earned
  return const _HexPalette(
    Color(0xFF374151),
    Color(0xFF1F2937),
    Color(0xFF111827),
    Color(0xFF6B7280),
  );
}


class _HexBadgePainter extends CustomPainter {
  final _HexPalette palette;
  _HexBadgePainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    Path hex(double radius) {
      final p = Path();
      for (int i = 0; i < 6; i++) {
        final theta = (math.pi / 3) * i - math.pi / 2;
        final x = center.dx + radius * math.cos(theta);
        final y = center.dy + radius * math.sin(theta);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
      return p;
    }

    final rim = Paint()..color = palette.rim;
    canvas.drawPath(hex(r), rim);

    final inner = Paint()
      ..shader = RadialGradient(
        colors: [palette.plateLight, palette.plateDark],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.82));
    canvas.drawPath(hex(r * 0.82), inner);
  }

  @override
  bool shouldRepaint(covariant _HexBadgePainter old) =>
      old.palette.rim != palette.rim ||
      old.palette.plateDark != palette.plateDark;
}


class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Your masteries will level up as you log workouts, steps, and cardio.',
        style: TextStyle(
          color:
              isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}


class _LoadingGrid extends StatelessWidget {
  final bool isDark;
  const _LoadingGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
