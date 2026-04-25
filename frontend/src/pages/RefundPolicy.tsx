import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

/**
 * Refund Policy — aligned with actual billing paths (Apple, Google, RevenueCat
 * web checkout if enabled) and EU Consumer Rights Directive 2011/83/EU
 * requirements. Changes here should be reviewed alongside TermsOfService.tsx
 * §3 (Subscriptions & Payments).
 */
export default function RefundPolicy() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          <p className="text-[13px] text-[var(--color-text-muted)] mb-4">Last updated: April 21, 2026</p>

          <h1
            className="text-[36px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-8"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Refund Policy
          </h1>

          <div className="space-y-8 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            <div>
              <p>
                We want you to be satisfied with FitWiz. This Refund Policy explains how refunds
                work, how to cancel, and what statutory rights you have if you live in the EU,
                UK, or Switzerland. FitWiz subscriptions are sold exclusively through the Apple
                App Store and Google Play; those stores are the merchant of record and their
                refund rules apply.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                1. Free Trial
              </h2>
              <p>
                FitWiz Premium starts with a 7-day free trial. You will not be charged during
                the trial. If you cancel before the trial ends (Apple: at least 24 hours before
                the trial's last day; Google: any time before it ends), you will not be billed.
                If you do not cancel, the trial converts to a paid subscription at the price
                shown at sign-up and renews until cancelled.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                2. App Store &amp; Google Play Purchases
              </h2>
              <p className="mb-4">
                Subscriptions purchased on iOS or Android are billed and managed by Apple or
                Google. Refund decisions for those purchases follow each platform's policy:
              </p>

              <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">Google Play</h3>
              <p className="mb-4">
                Request a refund at{' '}
                <a
                  href="https://support.google.com/googleplay/answer/2479637"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-emerald-400 hover:underline"
                >
                  Google Play's refund page
                </a>
                . Google automatically honors refunds within 48 hours of purchase and reviews
                later requests case-by-case.
              </p>

              <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">Apple App Store</h3>
              <p>
                Request a refund at{' '}
                <a
                  href="https://reportaproblem.apple.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-emerald-400 hover:underline"
                >
                  reportaproblem.apple.com
                </a>
                . Apple reviews each request individually.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                3. In-App Store Items
              </h2>
              <p className="mb-4">
                One-time purchases inside the FitWiz app (workout programs, meal plans,
                cosmetics, and similar digital content) are billed by Apple or Google at the
                moment of purchase and deliver immediately. They are generally non-refundable,
                but we will help arrange a refund through Apple or Google in the following
                situations:
              </p>
              <ul className="list-disc pl-6 space-y-1">
                <li>You were charged in error or could not access the item due to a technical issue we could not resolve.</li>
                <li>The item was materially different from its description.</li>
                <li>Duplicate purchases of the same product for the same account.</li>
              </ul>
              <p className="mt-4">
                Email{' '}
                <a href="mailto:support@fitwiz.us" className="text-emerald-400 hover:underline">support@fitwiz.us</a>{' '}
                with your order ID and a brief description and we will open a refund case with
                the relevant store on your behalf.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                4. EU / UK / Swiss Statutory Rights (Consumer Rights Directive)
              </h2>
              <p className="mb-4">
                If you live in the EEA, United Kingdom, or Switzerland you have a statutory
                right of withdrawal for 14 days after purchase of a digital service. Because
                FitWiz subscriptions are sold through the Apple App Store and Google Play, the
                store you bought from is the merchant of record and handles withdrawal requests
                through the refund flows in Section 2.
              </p>
              <p>
                Your statutory rights under consumer protection law, including any right to a
                remedy for defective digital content, are not affected by this policy. If a
                store declines a refund you believe you are statutorily entitled to, contact us
                at{' '}
                <a href="mailto:support@fitwiz.us" className="text-emerald-400 hover:underline">support@fitwiz.us</a>{' '}
                and we will advocate on your behalf.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                5. Double-Billing &amp; Accidental Charges
              </h2>
              <p>
                If you believe you have been billed twice for the same period, email{' '}
                <a href="mailto:support@fitwiz.us" className="text-emerald-400 hover:underline">support@fitwiz.us</a>{' '}
                with both receipts. We reconcile against RevenueCat, Apple, and Google billing
                records and will help you recover the overlap through the original store. We
                do not charge administrative fees for our own mistakes.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                6. How to Cancel Your Subscription
              </h2>
              <p className="mb-4">
                You can cancel your FitWiz Premium subscription at any time. Premium access
                continues through the end of the current billing period.
              </p>
              <ul className="list-disc pl-6 space-y-1">
                <li><strong className="text-[var(--color-text)]">Android:</strong> Google Play Store &gt; Menu &gt; Subscriptions &gt; FitWiz &gt; Cancel.</li>
                <li><strong className="text-[var(--color-text)]">iOS:</strong> Settings &gt; Apple ID &gt; Subscriptions &gt; FitWiz &gt; Cancel.</li>
                <li><strong className="text-[var(--color-text)]">In-app shortcut:</strong> Settings &gt; Subscription &gt; Manage (deep-links into the relevant store).</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                7. Chargebacks &amp; Disputes
              </h2>
              <p>
                Please contact us first — we can usually resolve concerns faster than a
                chargeback. If you file a chargeback for a charge we would have refunded, we
                may suspend the associated account until the bank or store resolves the dispute.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                8. Contact
              </h2>
              <p className="mb-2">
                <strong>Refund or billing questions:</strong>{' '}
                <a href="mailto:support@fitwiz.us" className="text-emerald-400 hover:underline">support@fitwiz.us</a>
              </p>
              <p className="mb-2">
                <strong>Privacy or data questions:</strong>{' '}
                <a href="mailto:privacy@fitwiz.us" className="text-emerald-400 hover:underline">privacy@fitwiz.us</a>
              </p>
              <p>We aim to respond within 2 business days.</p>
            </div>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
