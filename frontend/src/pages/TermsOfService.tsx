import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

export default function TermsOfService() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          <p className="text-[13px] text-[var(--color-text-muted)] mb-4">Last updated: February 26, 2026</p>

          <h1
            className="text-[36px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-8"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Terms of Service
          </h1>

          <div className="space-y-8 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            <div>
              <p>
                Welcome to FitWiz. By accessing or using the FitWiz mobile application and website (the "Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the Service.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                1. Eligibility
              </h2>
              <p>
                You must be at least 16 years old to use FitWiz. If you are between 16 and 18, you should review these Terms with a parent or guardian before using the Service. By creating an account, you represent that you are at least 16 years of age, that the information you provide is accurate, and that you meet these eligibility requirements. FitWiz collects sensitive health and fitness data and uses AI-powered services, which require the legal capacity to consent to data processing under applicable laws.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                2. Account Registration
              </h2>
              <p>
                You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must notify us immediately of any unauthorized use. We reserve the right to suspend or terminate accounts that violate these Terms.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                3. Subscriptions & Payments
              </h2>
              <p className="mb-4">
                FitWiz offers a free tier and a paid Premium subscription. Premium subscriptions are processed through RevenueCat via the Apple App Store or Google Play Store.
              </p>
              <ul className="list-disc pl-6 space-y-1">
                <li>Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current billing period.</li>
                <li>You can manage or cancel your subscription through your device's subscription settings (App Store or Google Play).</li>
                <li>Prices may change with reasonable notice. Existing subscribers will be notified before any price increase takes effect on their next renewal.</li>
                <li>Free trial periods, if offered, convert to paid subscriptions unless cancelled before the trial ends.</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                4. Health Disclaimer
              </h2>
              <p className="mb-4 font-semibold text-[var(--color-text)]">
                FitWiz is not a substitute for professional medical advice, diagnosis, or treatment.
              </p>
              <ul className="list-disc pl-6 space-y-1">
                <li>The AI-generated workout plans and nutrition recommendations are for informational purposes only.</li>
                <li>Always consult a qualified healthcare provider before starting any exercise program, especially if you have pre-existing medical conditions.</li>
                <li>FitWiz is not responsible for any injuries sustained while following AI-generated workout plans.</li>
                <li>If you experience pain, dizziness, or discomfort during exercise, stop immediately and seek medical attention.</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                5. Acceptable Use
              </h2>
              <p className="mb-4">You agree not to:</p>
              <ul className="list-disc pl-6 space-y-1">
                <li>Use the Service for any unlawful purpose</li>
                <li>Attempt to reverse-engineer, decompile, or hack the Service</li>
                <li>Upload harmful, offensive, or inappropriate content to social features</li>
                <li>Impersonate another user or misrepresent your identity</li>
                <li>Use automated systems (bots, scrapers) to access the Service</li>
                <li>Interfere with or disrupt the Service's infrastructure</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                6. Intellectual Property
              </h2>
              <p>
                All content, features, and functionality of FitWiz — including the exercise library, AI coaching algorithms, UI design, and branding — are owned by FitWiz and protected by copyright, trademark, and other intellectual property laws. You may not reproduce, distribute, or create derivative works without our express written permission.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                7. User-Generated Content
              </h2>
              <p>
                By posting content through FitWiz's social features (workout shares, progress photos, comments), you grant FitWiz a non-exclusive, worldwide, royalty-free license to display that content within the Service. You retain ownership of your content and can delete it at any time.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                8. Termination
              </h2>
              <p>
                We may suspend or terminate your access to the Service at any time for violation of these Terms, with or without notice. Upon termination, your right to use the Service ceases immediately. You may request deletion of your data by contacting us.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                9. Limitation of Liability
              </h2>
              <p>
                To the maximum extent permitted by law, FitWiz and its affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the Service. Our total liability shall not exceed the amount you paid for the Service in the 12 months preceding the claim.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                10. Disclaimer of Warranties
              </h2>
              <p>
                The Service is provided "as is" and "as available" without warranties of any kind, whether express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, and non-infringement. We do not guarantee that the Service will be uninterrupted, error-free, or free of harmful components.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                11. Changes to These Terms
              </h2>
              <p>
                We reserve the right to modify these Terms at any time. Material changes will be communicated through the app or via email. Your continued use of the Service after changes are posted constitutes acceptance of the revised Terms.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                12. Governing Law
              </h2>
              <p>
                These Terms shall be governed by and construed in accordance with the laws of the United States. Any disputes shall be resolved through binding arbitration in accordance with applicable rules.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                13. Contact Us
              </h2>
              <p>
                If you have questions about these Terms, please contact us at{' '}
                <a href="mailto:legal@fitwiz.app" className="text-emerald-400 hover:underline">
                  legal@fitwiz.app
                </a>.
              </p>
            </div>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
