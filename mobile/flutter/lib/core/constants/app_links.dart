/// Centralized external links, social media URLs, and app metadata.
///
/// All external URLs live here so they can be updated in one place.
/// Screens reference these constants instead of hardcoding URLs.
class AppLinks {
  AppLinks._();

  // ── Website ───────────────────────────────────────────────────────────────

  static const String website = 'https://fitwiz.us';

  // ── Social Media ──────────────────────────────────────────────────────────

  static const String discord = ''; // TODO: create and add Discord invite link
  static const String reddit = ''; // TODO: create and add subreddit URL
  static const String twitter = ''; // TODO: add X/Twitter profile URL
  static const String instagram = ''; // TODO: add Instagram profile URL
  static const String tiktok = ''; // TODO: add TikTok profile URL
  static const String youtube = ''; // TODO: add YouTube channel URL

  // ── Feature Requests & Community ──────────────────────────────────────────

  /// Where users go to suggest features and discuss ideas.
  /// Prefers Discord, falls back to Reddit.
  static String get featureRequests {
    if (discord.isNotEmpty) return discord;
    if (reddit.isNotEmpty) return reddit;
    return '';
  }

  /// Whether the feature request link is configured.
  static bool get hasFeatureRequestLink => featureRequests.isNotEmpty;

  // ── App Store Links ───────────────────────────────────────────────────────

  static const String playStore = 'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app';
  static const String appStore = ''; // TODO: add App Store listing URL

  // ── Legal & Support ───────────────────────────────────────────────────────

  static const String privacyPolicy = '$website/privacy';
  static const String termsOfService = '$website/terms';
  static const String faq = '$website/faq';
  static const String supportEmail = 'support@fitwiz.us';

  // ── Other Pages ───────────────────────────────────────────────────────────

  static const String changelog = '$website/changelog';
  static const String about = '$website/about';
  static const String contact = '$website/contact';
  static const String deleteAccount = '$website/delete-account';

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// All social links as a map for iteration (e.g., settings social row).
  /// Only includes links that are non-empty.
  static Map<String, String> get activeSocialLinks {
    final all = {
      'discord': discord,
      'reddit': reddit,
      'twitter': twitter,
      'instagram': instagram,
      'tiktok': tiktok,
      'youtube': youtube,
    };
    all.removeWhere((_, url) => url.isEmpty);
    return all;
  }
}
