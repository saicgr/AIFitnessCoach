part of 'neat_gamification_widgets.dart';


/// Individual leaderboard row
class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.cyan.withOpacity(0.1)
            : tc.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.cyan.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          _RankBadge(rank: entry.rank),
          const SizedBox(width: 12),

          // Avatar/initial
          CircleAvatar(
            radius: 18,
            backgroundColor: entry.level.color.withOpacity(0.2),
            child: Text(
              entry.displayName.isNotEmpty
                  ? entry.displayName[0].toUpperCase()
                  : '?',
              style: ZType.disp(16, color: entry.level.color),
            ),
          ),
          const SizedBox(width: 12),

          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.displayName,
                      style: ZType.ser(
                        15,
                        color: tc.textPrimary,
                        weight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (isCurrentUser)
                      Text(
                        ' (${AppLocalizations.of(context)!.commonYou})',
                        style: ZType.lbl(11, color: tc.accent, letterSpacing: 0.6),
                      ),
                  ],
                ),
                Text(
                  entry.level.localizedName(AppLocalizations.of(context)!),
                  style: ZType.lbl(11, color: entry.level.color, letterSpacing: 1.0),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.weeklyScore}',
                style: ZType.disp(20, color: tc.textPrimary, letterSpacing: 0),
              ),
              Text(
                AppLocalizations.of(context)!.neatGamificationWidgetsNeatPts,
                style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Rank badge widget for leaderboard positions
class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String? medal;

    switch (rank) {
      case 1:
        badgeColor = AppColors.yellow;
        medal = '\u{1F947}'; // Gold medal
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0); // Silver
        medal = '\u{1F948}'; // Silver medal
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronze
        medal = '\u{1F949}'; // Bronze medal
        break;
      default:
        badgeColor = AppColors.textMuted;
        medal = null;
    }

    if (medal != null) {
      return Text(
        medal,
        style: const TextStyle(fontSize: 24),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: ZType.disp(14, color: badgeColor, letterSpacing: 0),
        ),
      ),
    );
  }
}


/// Share button widget
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: ZType.lbl(14, color: Colors.white, letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}


/// Confetti particle data
class _ConfettiParticle {
  double x;
  double y;
  final double size;
  final Color color;
  final double velocity;
  double rotation;
  final double rotationSpeed;
  final double swayAmplitude;
  final double swayPhase;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.swayPhase,
  });
}


/// Custom painter for confetti animation
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      if (particle.y > 1.2) continue;

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        particle.x * size.width,
        particle.y * size.height,
      );
      canvas.rotate(particle.rotation * math.pi / 180);

      // Draw rectangle confetti
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}


class _CompactStatItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String subValue;
  final double progress;
  final Color progressColor;

  const _CompactStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: ZType.disp(20, color: tc.textPrimary, letterSpacing: 0),
              ),
              Text(
                subValue,
                style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Mini progress bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: tc.cardBorder,
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

