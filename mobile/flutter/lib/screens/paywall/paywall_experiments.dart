import 'package:flutter/foundation.dart';
import '../../core/services/posthog_service.dart';

/// Resolved A/B-experiment state for the paywall surfaces.
///
/// Every conversion lever defaults to its TREATMENT value, so the
/// improvements ship and run even with no PostHog experiment configured.
/// When a PostHog flag IS configured for a lever, its value overrides the
/// default — letting PostHog split traffic and measure uplift. A flag that
/// is absent or errors leaves the treatment default untouched (this is why
/// resolution uses [PosthogService.getFeatureFlag], which returns `null`
/// for an unconfigured flag, rather than `isFeatureEnabled`, which cannot
/// tell "absent" from "false").
///
/// One getter per lever; later paywall phases consume this object and do
/// not need to touch this file again.
@immutable
class PaywallExperiments {
  /// Phase A: "No payment due now" trust microcopy rendered DIRECTLY above
  /// the CTA button (on the soft paywall trial path), and the honest
  /// "Cancel anytime in Settings" microcopy above the hard-paywall CTA.
  final bool noPaymentMicrocopy;

  /// Phase A: "Billed securely through the App Store / Google Play" badge
  /// placed with the legal block.
  final bool secureCheckoutBadge;

  /// Phase B: methodology + technology credibility strip.
  final bool credibilityStrip;

  /// Phase C: pricing-psychology polish (savings-badge prominence, per-day
  /// comparison copy, de-emphasized monthly tab).
  final bool pricingPsychology;

  /// Phase D: hard-paywall 25%-off secondary offer.
  ///
  /// Defaults to FALSE. Pre-launch with no traction there is no reason to
  /// discount (it contradicts the held $7.99/$59.99 positioning and
  /// contaminates the first full-price conversion baseline), and the
  /// button as written advertises "$37.49/year" while routing to a screen
  /// that charges full price — a discount the destination cannot honor
  /// until the `premium_yearly_25off` SKU exists. Flip the PostHog flag
  /// `paywall_hard_paywall_discount` on only when a real discounted flow
  /// is built and a post-launch discount test is actually wanted.
  final bool hardPaywallDiscount;

  /// Phase D: soft-paywall "Maybe later" exit-intent discount offer.
  ///
  /// Defaults to FALSE — the discounted SKU (`premium_yearly_25off`) does
  /// not yet exist in Play Console / RevenueCat, so triggering this path
  /// would crash the purchase with "Product not found". Flip the PostHog
  /// flag `paywall_soft_exit_offer` on ONLY after that SKU is live; the
  /// code path is otherwise ready.
  final bool softPaywallExitOffer;

  const PaywallExperiments({
    required this.noPaymentMicrocopy,
    required this.secureCheckoutBadge,
    required this.credibilityStrip,
    required this.pricingPsychology,
    required this.hardPaywallDiscount,
    required this.softPaywallExitOffer,
  });

  /// Shipped defaults: the honest, no-discount conversion levers ON; both
  /// discount offers OFF for launch (no traction to win back yet, and the
  /// discounted SKU does not exist — see [hardPaywallDiscount] and
  /// [softPaywallExitOffer]).
  static const PaywallExperiments treatmentDefaults = PaywallExperiments(
    noPaymentMicrocopy: true,
    secureCheckoutBadge: true,
    credibilityStrip: true,
    pricingPsychology: true,
    hardPaywallDiscount: false,
    softPaywallExitOffer: false,
  );

  /// PostHog flag keys, one per lever. Create these in PostHog to A/B test;
  /// leave them unconfigured to ship the treatment for everyone.
  static const String flagNoPaymentMicrocopy = 'paywall_no_payment_microcopy';
  static const String flagSecureCheckoutBadge = 'paywall_secure_checkout_badge';
  static const String flagCredibilityStrip = 'paywall_credibility_strip';
  static const String flagPricingPsychology = 'paywall_pricing_psychology';
  static const String flagHardPaywallDiscount = 'paywall_hard_paywall_discount';
  static const String flagSoftPaywallExitOffer = 'paywall_soft_exit_offer';
}

/// Maps a raw PostHog flag value to an enabled/disabled bool.
///
/// - `bool` → used as-is.
/// - `String` → multivariate variant; "treatment"/"on"/"true"/"enabled"
///   count as enabled, anything else (e.g. "control") as disabled.
/// - `null` or any other type → flag absent/unreadable → [fallback] kept.
bool _resolveFlag(Object? raw, bool fallback) {
  if (raw is bool) return raw;
  if (raw is String) {
    final v = raw.toLowerCase();
    return v == 'treatment' || v == 'on' || v == 'true' || v == 'enabled';
  }
  return fallback;
}

/// Resolves [PaywallExperiments] from PostHog, falling back to
/// [PaywallExperiments.treatmentDefaults] for any lever whose flag is not
/// configured. Captures one `paywall_experiment_exposed` event per lever so
/// the variant a user actually saw is queryable alongside conversion events.
///
/// [surface] distinguishes where the resolution happened — pass
/// `'soft_paywall'` or `'hard_paywall'`. Never throws: PostHog wrapper
/// methods already swallow errors and return `null`.
Future<PaywallExperiments> loadPaywallExperiments(
  PosthogService posthog, {
  required String surface,
}) async {
  const defaults = PaywallExperiments.treatmentDefaults;

  Future<bool> resolve(String flagKey, bool fallback) async {
    final raw = await posthog.getFeatureFlag(flagKey);
    final value = _resolveFlag(raw, fallback);
    // Fire-and-forget exposure event — lets PostHog attribute conversions
    // to the variant actually rendered, including for the baked-in default.
    posthog.capture(
      eventName: 'paywall_experiment_exposed',
      properties: {
        'surface': surface,
        'flag': flagKey,
        'variant': value ? 'treatment' : 'control',
        'flag_configured': raw != null,
      },
    );
    return value;
  }

  // Resolve all levers in parallel — each is an independent network read.
  final results = await Future.wait<bool>([
    resolve(PaywallExperiments.flagNoPaymentMicrocopy,
        defaults.noPaymentMicrocopy),
    resolve(PaywallExperiments.flagSecureCheckoutBadge,
        defaults.secureCheckoutBadge),
    resolve(PaywallExperiments.flagCredibilityStrip,
        defaults.credibilityStrip),
    resolve(PaywallExperiments.flagPricingPsychology,
        defaults.pricingPsychology),
    resolve(PaywallExperiments.flagHardPaywallDiscount,
        defaults.hardPaywallDiscount),
    resolve(PaywallExperiments.flagSoftPaywallExitOffer,
        defaults.softPaywallExitOffer),
  ]);

  if (kDebugMode) {
    debugPrint('🎯 [Paywall] experiments resolved ($surface): '
        'noPaymentMicrocopy=${results[0]}, '
        'secureCheckoutBadge=${results[1]}, '
        'credibilityStrip=${results[2]}, '
        'pricingPsychology=${results[3]}, '
        'hardPaywallDiscount=${results[4]}, '
        'softPaywallExitOffer=${results[5]}');
  }

  return PaywallExperiments(
    noPaymentMicrocopy: results[0],
    secureCheckoutBadge: results[1],
    credibilityStrip: results[2],
    pricingPsychology: results[3],
    hardPaywallDiscount: results[4],
    softPaywallExitOffer: results[5],
  );
}
