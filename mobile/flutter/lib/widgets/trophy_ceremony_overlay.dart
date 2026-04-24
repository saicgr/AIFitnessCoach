import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/pending_celebration.dart';
import '../data/providers/pending_celebrations_provider.dart';
import '../data/services/haptic_service.dart';

/// Full-screen celebration ceremony matching the Garmin/Amazfit reference
/// (sunburst backdrop + metallic badge + gradient caption + swipeable
/// page-indicator for multi-trophy stacks).
///
/// Invoked by `maybeShowPendingCelebrations()` which reads the
/// `pendingCelebrationsProvider` queue and bails if it's empty. Safe to
/// call on every app resume / tab change — the provider dedupes via the
/// server-side `last_celebration_ack_at` cursor.
Future<void> showTrophyCeremony({
  required BuildContext context,
  required List<PendingCelebration> trophies,
}) async {
  if (trophies.isEmpty) return;
  HapticService.success();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black,
    barrierLabel: 'Trophy celebration',
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, __, ___) {
      return _TrophyCeremonyScreen(trophies: trophies);
    },
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Read the queue and surface the ceremony if non-empty, then ack. Call
/// from `MainShell.initState` / app-resume listener. Never throws — worst
/// case it's a no-op.
Future<void> maybeShowPendingCelebrations({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  // Refresh the queue server-side first so we honour the ack cursor.
  await ref.read(pendingCelebrationsProvider.notifier).refresh();
  final pending = ref.read(pendingCelebrationsProvider).pending;
  if (pending.isEmpty || !context.mounted) return;

  await showTrophyCeremony(context: context, trophies: pending);
  await ref.read(pendingCelebrationsProvider.notifier).ack();
}


// =========================================================================
// Ceremony screen — swipeable stack
// =========================================================================

class _TrophyCeremonyScreen extends ConsumerStatefulWidget {
  final List<PendingCelebration> trophies;

  const _TrophyCeremonyScreen({required this.trophies});

  @override
  ConsumerState<_TrophyCeremonyScreen> createState() =>
      _TrophyCeremonyScreenState();
}

class _TrophyCeremonyScreenState
    extends ConsumerState<_TrophyCeremonyScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  late final AnimationController _sunburstPulse;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _sunburstPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _sunburstPulse.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    HapticFeedback.selectionClick();
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trophies = widget.trophies;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Swipeable stack of trophies
            PageView.builder(
              controller: _controller,
              itemCount: trophies.length,
              onPageChanged: (i) {
                HapticService.light();
                setState(() => _index = i);
              },
              itemBuilder: (_, i) {
                final t = trophies[i];
                return _TrophySlide(
                  trophy: t,
                  sunburst: _sunburstPulse,
                  canvasSize: size,
                );
              },
            ),

            // Chevrons (only when there's somewhere to go)
            if (trophies.length > 1) ...[
              Positioned(
                left: 8,
                top: size.height / 2 - 24,
                child: _NavChevron(
                  icon: Icons.chevron_left_rounded,
                  enabled: _index > 0,
                  onTap: _index > 0 ? () => _goTo(_index - 1) : null,
                ),
              ),
              Positioned(
                right: 8,
                top: size.height / 2 - 24,
                child: _NavChevron(
                  icon: Icons.chevron_right_rounded,
                  enabled: _index < trophies.length - 1,
                  onTap: _index < trophies.length - 1
                      ? () => _goTo(_index + 1)
                      : null,
                ),
              ),
            ],

            // Close button
            Positioned(
              top: 8,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                tooltip: 'Close',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                },
              ),
            ),

            // Page indicator
            if (trophies.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: _PageDots(
                  count: trophies.length,
                  activeIndex: _index,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


// =========================================================================
// One trophy slide
// =========================================================================

class _TrophySlide extends StatelessWidget {
  final PendingCelebration trophy;
  final Animation<double> sunburst;
  final Size canvasSize;

  const _TrophySlide({
    required this.trophy,
    required this.sunburst,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    final shortest = canvasSize.shortestSide;
    final badgeSize = shortest * 0.52;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        // Badge + sunburst
        SizedBox(
          width: badgeSize * 1.9,
          height: badgeSize * 1.9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: sunburst,
                builder: (_, __) {
                  return CustomPaint(
                    size: Size(badgeSize * 1.9, badgeSize * 1.9),
                    painter: _SunburstPainter(
                      progress: sunburst.value,
                      tier: trophy.tier,
                    ),
                  );
                },
              ),
              _BadgeEmblem(
                trophy: trophy,
                size: badgeSize,
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // Title + Lv chip
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                trophy.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (trophy.level != null) ...[
              const SizedBox(width: 8),
              _LvChip(level: trophy.level!),
            ],
          ],
        ),
        const SizedBox(height: 14),
        // Gradient caption — green → cyan matches the reference art
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFF4ADE80), Color(0xFF22D3EE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(rect),
            child: Text(
              trophy.description.isEmpty
                  ? 'Congrats on earning this trophy!'
                  : trophy.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Date stamp
        Text(
          _formatDate(trophy.earnedAt),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}


// =========================================================================
// Metallic badge emblem (hexagonal / circular by tier)
// =========================================================================

class _BadgeEmblem extends StatelessWidget {
  final PendingCelebration trophy;
  final double size;

  const _BadgeEmblem({required this.trophy, required this.size});

  @override
  Widget build(BuildContext context) {
    // Emoji → render as big glyph inside a metallic plate (current
    // schema stores trophy icons as emoji most of the time).
    // If the server ever returns a material-key icon we render that
    // via the fallback branch below.
    final iconString = trophy.icon;
    final isEmoji = iconString.runes.length <= 4 &&
        iconString.codeUnits.first > 127;

    final palette = _tierPalette(trophy.tier);
    final isHex = trophy.level != null;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BadgePlatePainter(palette: palette, hex: isHex),
        child: Center(
          child: isEmoji
              ? Text(
                  iconString,
                  style: TextStyle(fontSize: size * 0.42),
                )
              : Icon(
                  Icons.emoji_events_rounded,
                  size: size * 0.42,
                  color: palette.glyph,
                ),
        ),
      ),
    );
  }
}


class _BadgePlatePainter extends CustomPainter {
  final _TierPalette palette;
  final bool hex;

  _BadgePlatePainter({required this.palette, required this.hex});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    Path shape;
    if (hex) {
      shape = Path();
      for (int i = 0; i < 6; i++) {
        final theta = (math.pi / 3) * i - math.pi / 2;
        final x = center.dx + r * math.cos(theta);
        final y = center.dy + r * math.sin(theta);
        if (i == 0) {
          shape.moveTo(x, y);
        } else {
          shape.lineTo(x, y);
        }
      }
      shape.close();
    } else {
      shape = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    }

    // Outer rim
    final rim = Paint()
      ..shader = RadialGradient(
        colors: [palette.rimLight, palette.rimDark],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawPath(shape, rim);

    // Inner plate
    final inner = Path();
    if (hex) {
      final innerR = r * 0.78;
      for (int i = 0; i < 6; i++) {
        final theta = (math.pi / 3) * i - math.pi / 2;
        final x = center.dx + innerR * math.cos(theta);
        final y = center.dy + innerR * math.sin(theta);
        if (i == 0) {
          inner.moveTo(x, y);
        } else {
          inner.lineTo(x, y);
        }
      }
      inner.close();
    } else {
      inner.addOval(Rect.fromCircle(center: center, radius: r * 0.78));
    }
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [palette.plateLight, palette.plateDark],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.78));
    canvas.drawPath(inner, innerPaint);

    // Subtle inner shadow on bottom edge
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 4);
    canvas.drawPath(inner, shadow);
  }

  @override
  bool shouldRepaint(covariant _BadgePlatePainter old) =>
      old.palette != palette || old.hex != hex;
}


// =========================================================================
// Sunburst backdrop — radiating rays behind the badge
// =========================================================================

class _SunburstPainter extends CustomPainter {
  final double progress; // 0..1 pulse
  final String tier;

  _SunburstPainter({required this.progress, required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide / 2;
    // Pulse between 0.95× and 1.05× so the rays feel alive without
    // becoming distracting.
    final scale = 0.95 + 0.10 * progress;
    final palette = _tierPalette(tier);

    final rays = Paint()
      ..color = palette.sunburst.withValues(alpha: 0.6 + 0.3 * progress)
      ..style = PaintingStyle.fill;

    const rayCount = 28;
    for (int i = 0; i < rayCount; i++) {
      final theta = (2 * math.pi / rayCount) * i;
      final half = (math.pi / rayCount) * 0.45;
      final r1 = outerR * 0.40 * scale;
      final r2 = outerR * 0.98 * scale;

      final p = Path()
        ..moveTo(
          center.dx + r1 * math.cos(theta - half),
          center.dy + r1 * math.sin(theta - half),
        )
        ..lineTo(
          center.dx + r2 * math.cos(theta - half * 0.15),
          center.dy + r2 * math.sin(theta - half * 0.15),
        )
        ..lineTo(
          center.dx + r2 * math.cos(theta + half * 0.15),
          center.dy + r2 * math.sin(theta + half * 0.15),
        )
        ..lineTo(
          center.dx + r1 * math.cos(theta + half),
          center.dy + r1 * math.sin(theta + half),
        )
        ..close();
      canvas.drawPath(p, rays);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter old) =>
      old.progress != progress || old.tier != tier;
}


// =========================================================================
// Tier palette
// =========================================================================

class _TierPalette {
  final Color rimLight;
  final Color rimDark;
  final Color plateLight;
  final Color plateDark;
  final Color glyph;
  final Color sunburst;

  const _TierPalette({
    required this.rimLight,
    required this.rimDark,
    required this.plateLight,
    required this.plateDark,
    required this.glyph,
    required this.sunburst,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _TierPalette &&
          rimLight == other.rimLight &&
          rimDark == other.rimDark &&
          plateLight == other.plateLight &&
          plateDark == other.plateDark);

  @override
  int get hashCode =>
      rimLight.hashCode ^ rimDark.hashCode ^ plateLight.hashCode ^ plateDark.hashCode;
}

_TierPalette _tierPalette(String tier) {
  switch (tier) {
    case 'platinum':
      return const _TierPalette(
        rimLight: Color(0xFFE5E7EB),
        rimDark: Color(0xFF6B7280),
        plateLight: Color(0xFFF3F4F6),
        plateDark: Color(0xFFD1D5DB),
        glyph: Color(0xFF1F2937),
        sunburst: Color(0xFFFBBF24),
      );
    case 'gold':
      return const _TierPalette(
        rimLight: Color(0xFFFCD34D),
        rimDark: Color(0xFF92400E),
        plateLight: Color(0xFFFDE68A),
        plateDark: Color(0xFFF59E0B),
        glyph: Color(0xFF78350F),
        sunburst: Color(0xFFFBBF24),
      );
    case 'silver':
      return const _TierPalette(
        rimLight: Color(0xFFE5E7EB),
        rimDark: Color(0xFF6B7280),
        plateLight: Color(0xFFF3F4F6),
        plateDark: Color(0xFF9CA3AF),
        glyph: Color(0xFF1F2937),
        sunburst: Color(0xFFFBBF24),
      );
    case 'bronze':
    default:
      return const _TierPalette(
        rimLight: Color(0xFFF59E0B),
        rimDark: Color(0xFF78350F),
        plateLight: Color(0xFFFCD34D),
        plateDark: Color(0xFFB45309),
        glyph: Color(0xFF451A03),
        sunburst: Color(0xFFFBBF24),
      );
  }
}


// =========================================================================
// Small helpers
// =========================================================================

class _LvChip extends StatelessWidget {
  final int level;
  const _LvChip({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        'Lv.$level',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NavChevron extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _NavChevron({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 0.9 : 0.25,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 36),
        onPressed: onTap,
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  const _PageDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == activeIndex ? 18 : 8,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: i == activeIndex ? 0.9 : 0.35,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
