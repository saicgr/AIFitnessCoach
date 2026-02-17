import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

export default function PrivacyPolicy() {
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
            Privacy Policy
          </h1>

          <div className="space-y-8 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            <div>
              <p>
                FitWiz ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use the FitWiz mobile application and website (collectively, the "Service").
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                1. Information We Collect
              </h2>

              <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">Personal Information</h3>
              <p className="mb-4">When you create an account, we collect:</p>
              <ul className="list-disc pl-6 space-y-1 mb-4">
                <li>Name and email address</li>
                <li>Age, gender, height, and weight</li>
                <li>Fitness goals and experience level</li>
                <li>Profile photo (optional)</li>
              </ul>

              <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">Health & Fitness Data</h3>
              <p className="mb-4">To provide personalized coaching, we collect:</p>
              <ul className="list-disc pl-6 space-y-1 mb-4">
                <li>Workout history and exercise logs</li>
                <li>Body measurements and progress photos</li>
                <li>Nutrition and meal logs</li>
                <li>Fasting schedules and hydration data</li>
                <li>Heart rate data (if connected via Bluetooth monitor)</li>
                <li>Apple Health or Google Fit data (if sync is enabled)</li>
              </ul>

              <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">Usage Data</h3>
              <p className="mb-4">We automatically collect:</p>
              <ul className="list-disc pl-6 space-y-1">
                <li>Device type, operating system, and app version</li>
                <li>Feature usage patterns and session duration</li>
                <li>Crash logs and performance data</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                2. How We Use Your Information
              </h2>
              <p className="mb-4">We use the information we collect to:</p>
              <ul className="list-disc pl-6 space-y-1">
                <li>Generate personalized AI workout plans using Google Gemini</li>
                <li>Provide real-time AI coaching through our multi-agent chat system</li>
                <li>Track your fitness progress and provide analytics</li>
                <li>Calculate adaptive TDEE and nutrition recommendations</li>
                <li>Send workout reminders and motivational notifications</li>
                <li>Improve our Service and develop new features</li>
                <li>Respond to customer support inquiries</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                3. How We Share Your Information
              </h2>
              <p className="mb-4">We do not sell your personal data. We share information only with:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>
                  <strong className="text-[var(--color-text)]">Supabase</strong> — Our database and authentication provider, which stores your account and fitness data securely.
                </li>
                <li>
                  <strong className="text-[var(--color-text)]">Google (Gemini AI)</strong> — Your fitness profile and workout preferences are sent to Google's Gemini API to generate personalized workout plans and coaching responses. This data is not used by Google to train models.
                </li>
                <li>
                  <strong className="text-[var(--color-text)]">RevenueCat</strong> — Our payment processor for managing subscriptions. They receive only the data necessary to process payments.
                </li>
                <li>
                  <strong className="text-[var(--color-text)]">Firebase</strong> — Used for push notifications and crash analytics.
                </li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                4. Data Security
              </h2>
              <p>
                We implement industry-standard security measures to protect your data, including HTTPS encryption for all data in transit, JWT-based authentication, and secure cloud infrastructure. However, no method of electronic transmission or storage is 100% secure, and we cannot guarantee absolute security.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                5. Data Retention
              </h2>
              <p>
                We retain your personal data for as long as your account is active or as needed to provide the Service. If you delete your account, we will delete your personal data within 30 days, except where we are required to retain it for legal obligations.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                6. Your Rights
              </h2>
              <p className="mb-4">You have the right to:</p>
              <ul className="list-disc pl-6 space-y-1">
                <li>Access, update, or correct your personal information</li>
                <li>Request deletion of your account and associated data</li>
                <li>Export your fitness data in a portable format</li>
                <li>Opt out of non-essential notifications</li>
                <li>Disconnect Apple Health or Google Fit syncing at any time</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                7. Children's Privacy
              </h2>
              <p>
                FitWiz is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we discover that we have collected data from a child under 13, we will promptly delete it.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                8. Changes to This Policy
              </h2>
              <p>
                We may update this Privacy Policy from time to time. We will notify you of material changes by posting the updated policy in the app and updating the "Last updated" date above.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                9. Contact Us
              </h2>
              <p>
                If you have questions about this Privacy Policy or your data, please contact us at{' '}
                <a href="mailto:privacy@fitwiz.app" className="text-emerald-400 hover:underline">
                  privacy@fitwiz.app
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
