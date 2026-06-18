import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_theme.dart';
import '_value_beat_scaffold.dart';

/// Value beat: store rating + testimonials.
///
/// ANTI-FABRICATION CONTRACT — this is the whole point of this widget's API:
/// it NEVER invents ratings, review counts, or @handles. ALL content arrives
/// via params:
///   - [rating]        the live store rating (e.g. 4.8), or null if unknown
///   - [ratingCount]   number of ratings backing it, or null
///   - [testimonials]  real (handle, quote) pairs pulled from real reviews
///
/// If [rating] is null OR [testimonials] is empty, the widget renders a
/// tasteful CAPABILITY-LED variant instead ("Built by lifters, tuned every
/// week") — it does NOT show a star block or fake quotes. The host is expected
/// to pass only verified data; passing nothing is safe and degrades cleanly.
///
/// Returns just a [Padding]/[Column] body — the host quiz scaffold provides the
/// [OnboardingBackground] + [Scaffold].
class SocialProofBeat extends StatelessWidget {
  /// Advances the funnel to the next quiz step.
  final VoidCallback onContinue;

  /// Live store rating (e.g. 4.8). Null when not yet available — triggers the
  /// capability-led variant.
  final double? rating;

  /// Number of ratings backing [rating]. Optional even when [rating] is set.
  final int? ratingCount;

  /// Real review excerpts. Each entry is a (handle, quote) record. Empty list
  /// triggers the capability-led variant.
  final List<({String handle, String quote})> testimonials;

  const SocialProofBeat({
    super.key,
    required this.onContinue,
    this.rating,
    this.ratingCount,
    this.testimonials = const [],
  });

  /// True when we have enough verified data to show ratings + quotes.
  bool get _hasProof => rating != null && testimonials.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _hasProof
                  ? _proofVariant(t)
                  : _capabilityVariant(t),
            ),
          ),
          const SizedBox(height: 12),
          ValueBeatContinueButton(onContinue: onContinue)
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Variant A: verified rating + real testimonials ──────────────────
  Widget _proofVariant(OnboardingTheme t) {
    final r = rating!;
    final countText = ratingCount != null
        ? '${_compactCount(ratingCount!)} ratings'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const ValueBeatHeadline(
          headline: 'Lifters trust the plan.',
        ),
        const SizedBox(height: 24),
        // Rating block.
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: t.cardFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.borderDefault, width: 1),
          ),
          child: Row(
            children: [
              Text(
                r.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StarRow(rating: r, color: t.accent),
                  if (countText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      countText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),
        const SizedBox(height: 16),
        // Testimonials.
        ...List.generate(testimonials.length, (i) {
          final tm = testimonials[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i == testimonials.length - 1 ? 0 : 12,
            ),
            child: _TestimonialCard(t: t, handle: tm.handle, quote: tm.quote)
                .animate()
                .fadeIn(delay: (350 + i * 120).ms)
                .slideX(begin: -0.05),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Variant B: capability-led (no fabricated proof) ─────────────────
  Widget _capabilityVariant(OnboardingTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const ValueBeatHeadline(
          headline: 'Built by lifters,\ntuned every week.',
          supporting:
              'Not a static template. The plan engine is refined from how '
              'real training actually progresses.',
        ),
        const SizedBox(height: 28),
        ...[
          const ValueBeatCheckBullet(
            icon: Icons.science_rounded,
            title: 'Grounded in proven training principles',
            subtitle: 'Progressive overload, recovery, and balance — not hype.',
          ),
          const ValueBeatCheckBullet(
            icon: Icons.tune_rounded,
            title: 'Adapts as you log',
            subtitle: 'Every session you complete sharpens the next one.',
          ),
          const ValueBeatCheckBullet(
            icon: Icons.update_rounded,
            title: 'Improved continuously',
            subtitle: 'The engine gets smarter with each release.',
          ),
        ].animateStaggered(),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Compacts large counts: 12000 -> "12K", 1500000 -> "1.5M".
  String _compactCount(int n) {
    if (n >= 1000000) {
      final v = n / 1000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}K';
    }
    return '$n';
  }
}

/// Renders up to 5 stars for [rating], including a half star.
class _StarRow extends StatelessWidget {
  final double rating;
  final Color color;

  const _StarRow({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.25 && (rating - full) < 0.75;
    final roundedUp = (rating - full) >= 0.75;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (i < full || (i == full && roundedUp)) {
          icon = Icons.star_rounded;
        } else if (i == full && hasHalf) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: 20, color: color);
      }),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final OnboardingTheme t;
  final String handle;
  final String quote;

  const _TestimonialCard({
    required this.t,
    required this.handle,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderDefault, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$quote"',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            handle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: t.accent,
            ),
          ),
        ],
      ),
    );
  }
}

extension _StaggerBullets on List<Widget> {
  List<Widget> animateStaggered() {
    final out = <Widget>[];
    for (var i = 0; i < length; i++) {
      out.add(
        this[i]
            .animate()
            .fadeIn(delay: (300 + i * 120).ms)
            .slideX(begin: -0.06),
      );
      if (i != length - 1) out.add(const SizedBox(height: 18));
    }
    return out;
  }
}
