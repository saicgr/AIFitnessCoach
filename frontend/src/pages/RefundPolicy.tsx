import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

export default function RefundPolicy() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          <p className="text-[13px] text-[var(--color-text-muted)] mb-4">Last updated: February 16, 2026</p>

          <h1
            className="text-[36px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-8"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Refund Policy
          </h1>

          <div className="space-y-8 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            <div>
              <p>
                We want you to be satisfied with FitWiz. This Refund Policy explains how refunds work for our subscription and digital products.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                1. Subscription Refunds
              </h2>
              <p className="mb-4">
                FitWiz Premium subscriptions are processed through the Apple App Store or Google Play Store. Refund policies for subscriptions are governed by the respective app store:
              </p>

              <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">Google Play Store</h3>
              <p className="mb-4">
                To request a refund for a Google Play purchase, visit{' '}
                <a
                  href="https://support.google.com/googleplay/answer/2479637"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-emerald-400 hover:underline"
                >
                  Google Play's refund page
                </a>{' '}
                or contact Google Play support. Google typically processes refund requests within 48 hours of purchase.
              </p>

              <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">Apple App Store</h3>
              <p>
                To request a refund for an App Store purchase, visit{' '}
                <a
                  href="https://reportaproblem.apple.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-emerald-400 hover:underline"
                >
                  reportaproblem.apple.com
                </a>{' '}
                and follow the instructions. Apple reviews refund requests on a case-by-case basis.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                2. Free Trial
              </h2>
              <p>
                FitWiz Premium offers a 7-day free trial. If you cancel before the trial period ends, you will not be charged. If you do not cancel, your subscription will automatically convert to a paid subscription at the end of the trial period.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                3. Digital Store Products
              </h2>
              <p className="mb-4">
                Purchases made through the FitWiz Store (workout programs, meal plans, and other digital products) are non-refundable due to the nature of digital goods. However, we may consider refunds in the following cases:
              </p>
              <ul className="list-disc pl-6 space-y-1">
                <li>You were charged in error or experienced a technical issue preventing access</li>
                <li>The product was significantly different from its description</li>
                <li>Duplicate purchases</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                4. How to Cancel Your Subscription
              </h2>
              <p className="mb-4">
                You can cancel your FitWiz Premium subscription at any time. Your access to Premium features will continue until the end of your current billing period.
              </p>
              <ul className="list-disc pl-6 space-y-1">
                <li><strong className="text-[var(--color-text)]">Android:</strong> Open Google Play Store &gt; Menu &gt; Subscriptions &gt; FitWiz &gt; Cancel</li>
                <li><strong className="text-[var(--color-text)]">iOS:</strong> Open Settings &gt; Apple ID &gt; Subscriptions &gt; FitWiz &gt; Cancel</li>
                <li><strong className="text-[var(--color-text)]">In-App:</strong> Go to Settings &gt; Subscription &gt; Manage</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                5. Contact Us
              </h2>
              <p>
                If you have questions about refunds or need assistance, please contact us at{' '}
                <a href="mailto:support@fitwiz.app" className="text-emerald-400 hover:underline">
                  support@fitwiz.app
                </a>. We aim to respond to all inquiries within 24 hours.
              </p>
            </div>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
