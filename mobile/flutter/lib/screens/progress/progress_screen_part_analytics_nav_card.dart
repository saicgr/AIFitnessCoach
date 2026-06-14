part of 'progress_screen.dart';


/// Navigation card for analytics sections.
///
/// STATS HUB redesign: a hairline-outlined ZealovaCard — plain outlined icon,
/// Barlow uppercase title, muted subtitle, and a Barlow "VIEW →" affordance.
/// No gradient chip, no per-card accent tint (keeps the nav grid free of a
/// second accent). The incoming [color] is retained on the constructor for
/// callers but is no longer used to tint the surface.
class _AnalyticsNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AnalyticsNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tc.textSecondary, size: 22),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: ZType.lbl(13, color: tc.textPrimary, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: ZType.lbl(10.5,
                color: tc.textMuted,
                weight: FontWeight.w600,
                letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).setTrackingOverlayView.toUpperCase(),
                style: ZType.lbl(10,
                    color: tc.textMuted,
                    weight: FontWeight.w700,
                    letterSpacing: 1.2),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 13, color: tc.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
