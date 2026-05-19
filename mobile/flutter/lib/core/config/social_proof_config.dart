/// A single real, verbatim user testimonial. NEVER fabricated.
class PaywallTestimonial {
  final String quote;

  /// Short attribution, e.g. "Maria R." or "App Store review".
  final String attribution;

  const PaywallTestimonial({
    required this.quote,
    required this.attribution,
  });
}

/// Founder-supplied REAL social proof for the paywall.
///
/// Zealova is new and has no traction yet, so every field below is empty.
/// These MUST stay empty until the numbers and quotes are genuine — App
/// Store and Google Play review guidelines, and basic honesty, both forbid
/// invented ratings, user counts, or testimonials.
///
/// The paywall credibility widget ([PaywallCredibilityStrip]) reads these
/// fields and renders the rating / user-count / testimonial elements ONLY
/// when the data is real. While empty, the paywall falls back to
/// no-traction credibility (training methodology + technology), which needs
/// no numbers. The moment a founder fills a real value here, the matching
/// element appears with no other code change.
class SocialProofConfig {
  const SocialProofConfig._();

  /// Average store rating (e.g. 4.8). Keep `null` until it is real.
  static const double? storeRating = null;

  /// Number of ratings behind [storeRating]. Keep `null` until it is real.
  static const int? ratingCount = null;

  /// Approximate real installs / active users (e.g. 12000). Keep `null`
  /// until it is real and defensible.
  static const int? userCount = null;

  /// Real, verbatim testimonials with attribution. Keep empty until real.
  static const List<PaywallTestimonial> testimonials = <PaywallTestimonial>[];

  /// True only when a real store rating AND its count are both set.
  static bool get hasRating =>
      storeRating != null && ratingCount != null && ratingCount! > 0;

  /// True only when a real, positive user count is set.
  static bool get hasUserCount => userCount != null && userCount! > 0;

  /// True only when at least one real testimonial is set.
  static bool get hasTestimonials => testimonials.isNotEmpty;

  /// Formats [userCount] compactly: 12000 -> "12,000", 1500000 -> "1.5M".
  /// Returns `null` when there is no real count to show.
  static String? get formattedUserCount {
    final c = userCount;
    if (c == null || c <= 0) return null;
    if (c >= 1000000) {
      final m = c / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M';
    }
    if (c >= 1000) {
      final s = c.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return c.toString();
  }
}
