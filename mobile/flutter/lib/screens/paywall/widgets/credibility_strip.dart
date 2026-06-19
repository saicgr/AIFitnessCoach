import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/config/social_proof_config.dart';
import '../../../core/config/science_citations.dart';
import '../../../widgets/citation_link.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Standard gold used for rating stars across app stores.
const Color _kStarGold = Color(0xFFF5A623);

/// Trust / credibility block for the paywall surfaces.
///
/// Zealova is new and has no ratings, user counts, or testimonials yet, so
/// this widget leads with credibility levers that need ZERO traction data:
///   - technology credibility ("Powered by Google Gemini")
///   - training-methodology grounding ("Grounded in NSCA & NASM standards")
///   - a real safety differentiator ("Injury-aware programming")
///
/// It ALSO reads [SocialProofConfig]: the moment a founder fills in a real
/// store rating, user count, or testimonial there, the matching element
/// appears here with no change to this widget. Nothing fabricated is ever
/// rendered.
///
/// [accent] is passed by the caller so each surface uses its own correct
/// accent (the pricing screen's fixed warm-orange, or the theme accent
/// elsewhere) — the widget never hardcodes a brand color.
///
/// [compact] = a single condensed row of chips for dense surfaces (pricing
/// card, hard paywall). Full mode additionally renders the user-count line
/// and a scrollable testimonial row when that real data exists.
class PaywallCredibilityStrip extends StatelessWidget {
  final ThemeColors colors;
  final Color accent;
  final bool compact;

  const PaywallCredibilityStrip({
    super.key,
    required this.colors,
    required this.accent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    // Tier 1 — real social proof, rendered ONLY when it genuinely exists.
    if (SocialProofConfig.hasRating) {
      children.add(_ratingRow(context));
    }
    if (!compact && SocialProofConfig.hasUserCount) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(_userCountRow(context));
    }

    // Tier 2 — no-traction credibility chips. Always shown (the treatment).
    if (children.isNotEmpty) children.add(const SizedBox(height: 10));
    children.add(_chips());

    // Tier 3 — real testimonials, full mode only, only when they exist.
    if (!compact && SocialProofConfig.hasTestimonials) {
      children.add(const SizedBox(height: 12));
      children.add(_testimonials());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _ratingRow(BuildContext context) {
    final rating = SocialProofConfig.storeRating!;
    final count = SocialProofConfig.ratingCount!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.round();
          return Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: _kStarGold,
          );
        }),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.credibilityStripRatings(rating.toStringAsFixed(1), count),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _userCountRow(BuildContext context) {
    final formatted = SocialProofConfig.formattedUserCount;
    if (formatted == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.people_alt_outlined, size: 14, color: accent),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.credibilityStripJoinPeopleTrainingWith(formatted),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chips() {
    // Compact surfaces show the two strongest signals only; full mode
    // shows all three. Every claim here is true and needs no traction.
    //
    // The third element of each tuple is an optional [ScienceCitation]: when
    // present the chip becomes tappable and opens the primary source
    // ("verify-me beats trust-me"). Only the NSCA/NASM grounding chip carries
    // one (full mode) — the tech-credibility and injury-aware chips stay
    // non-tappable and unchanged.
    final items = compact
        ? const <(IconData, String, ScienceCitation?)>[
            (Icons.auto_awesome, 'Powered by Google Gemini', null),
            (Icons.health_and_safety_outlined, 'Injury-aware', null),
          ]
        : <(IconData, String, ScienceCitation?)>[
            (Icons.auto_awesome, 'Powered by Google Gemini', null),
            (
              Icons.school_outlined,
              'Grounded in NSCA & NASM standards',
              ScienceCitations.progressiveOverload,
            ),
            (Icons.health_and_safety_outlined, 'Injury-aware programming', null),
          ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((it) => _CredChip(
                icon: it.$1,
                label: it.$2,
                colors: colors,
                accent: accent,
                citation: it.$3,
              ))
          .toList(),
    );
  }

  Widget _testimonials() {
    final items = SocialProofConfig.testimonials;
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = items[i];
          return Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (_) => const Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: _kStarGold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.credibilityStripValue(t.quote),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.attribution,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A single rounded credibility pill: small icon + short label.
///
/// When [citation] is non-null the pill becomes tappable: a tiny "↗" affords
/// the tap, and pressing opens the primary source with a subtle scale +
/// haptic, consistent with [CitationLink]. Non-citation pills render exactly
/// as before (no decoration / interaction change).
class _CredChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final ThemeColors colors;
  final Color accent;
  final ScienceCitation? citation;

  const _CredChip({
    required this.icon,
    required this.label,
    required this.colors,
    required this.accent,
    this.citation,
  });

  @override
  State<_CredChip> createState() => _CredChipState();
}

class _CredChipState extends State<_CredChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.citation != null;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 13, color: widget.accent),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: widget.colors.textSecondary,
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 4),
            Text(
              '↗',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: widget.accent,
              ),
            ),
          ],
        ],
      ),
    );

    if (!tappable) return chip;

    return Semantics(
      link: true,
      label: '${widget.citation!.source}. Opens the source in your browser.',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          openCitation(widget.citation!);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: chip,
        ),
      ),
    );
  }
}
