import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

/**
 * Privacy Policy — must stay aligned with mobile/flutter/privacy_policy.html
 * and the server-side enforcement in backend/services/consent_guard.py and
 * backend/core/gemini_client.py. Changes here without matching changes on
 * the backend create the "promised but unimplemented" pattern flagged in
 * the April 2026 privacy audit.
 */
export default function PrivacyPolicy() {
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
            Privacy Policy
          </h1>

          <div className="space-y-8 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            <div>
              <p>
                FitWiz ("we", "our", or "us") operates the FitWiz mobile application and the
                website at fitwiz.us (together, the "Service"). This Privacy Policy explains what
                personal data we collect, how we use it, who we share it with, and the rights you
                have over it. It applies to residents of every country but includes specific
                provisions for users in the European Economic Area (EEA), United Kingdom,
                Switzerland, and California.
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
                <li>Fitness goals, experience level, equipment, and stated limitations</li>
                <li>Profile photo (optional)</li>
              </ul>

              <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">Health &amp; Fitness Data (Special Category)</h3>
              <p className="mb-4">To provide personalized coaching, we collect:</p>
              <ul className="list-disc pl-6 space-y-1 mb-4">
                <li>Workout history and exercise logs (sets, reps, weights, RPE)</li>
                <li>Body measurements and progress photos</li>
                <li>Nutrition and meal logs (including photos you upload)</li>
                <li>Hydration, fasting, and sleep data</li>
                <li>Heart rate, HRV, and other signals from connected devices</li>
                <li>Apple HealthKit / Google Health Connect data if you enable sync</li>
                <li>Menstrual cycle and hormonal health logs (optional)</li>
                <li>Exercise form videos you upload for technique feedback</li>
              </ul>

              <h3 className="text-[17px] font-semibold text-[var(--color-text)] mb-2">Usage &amp; Device Data</h3>
              <ul className="list-disc pl-6 space-y-1">
                <li>Device type, operating system, app version</li>
                <li>Feature usage, screens visited, session duration</li>
                <li>Crash reports and performance traces</li>
                <li>IP address (used only for security and approximate region)</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                2. How We Use Your Information
              </h2>
              <ul className="list-disc pl-6 space-y-1">
                <li>Generate personalized workout plans, nutrition suggestions, and coach replies</li>
                <li>Track your fitness progress and produce analytics on your own data</li>
                <li>Send workout reminders and opt-in push / email notifications</li>
                <li>Process payments and manage subscriptions</li>
                <li>Detect fraud, abuse, and security incidents</li>
                <li>Comply with legal obligations</li>
              </ul>
              <p className="mt-4">
                We do <strong>not</strong> sell your personal data. We do not use your personal
                data for third-party advertising, and we do not allow any sub-processor to use
                your content to train their models.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                3. Model-Powered Features &amp; Zero Data Retention
              </h2>
              <p className="mb-4">
                Several features — the coach chat, workout generation, food photo recognition,
                and exercise form video analysis — rely on large language and vision models hosted
                by Google Cloud on our behalf. When you use those features, relevant portions of
                your data (chat messages, the image or video you uploaded, your profile summary,
                your account ID) are transmitted over TLS to a Google Cloud Vertex AI endpoint we
                operate.
              </p>
              <p className="mb-4">
                Production traffic runs under Vertex AI's <strong>zero-data-retention</strong>
                (ZDR) configuration. Under that configuration:
              </p>
              <ul className="list-disc pl-6 space-y-1 mb-4">
                <li>Your prompts and responses are not retained by Google beyond the request.</li>
                <li>Your content is not used to train or improve any foundation model.</li>
                <li>Our backend refuses to initialize in production without this configuration,
                  so the consumer Developer API (which does not offer equivalent guarantees) is
                  never used for your data.</li>
              </ul>
              <p>
                You can pause this at any time in the app under{' '}
                <strong>Settings → Privacy &amp; Data → Personalization</strong>. When the toggle
                is off, our backend refuses to forward your chats, photos, or videos to the
                Vertex AI endpoint. You can also disable "Save chat history" to stop transcripts
                from being stored on our side.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                4. Health Data &mdash; Explicit Consent (GDPR Art. 9)
              </h2>
              <p className="mb-4">
                Weight, heart rate, sleep, menstrual cycle, hormonal, and similar physiological
                measurements are <strong>special category data</strong> under GDPR Art. 9 and
                are treated as health information under the California Confidentiality of Medical
                Information Act (CMIA). We process this data only after you give a separate,
                explicit opt-in that is not bundled with accepting the Terms of Service.
              </p>
              <p className="mb-4">
                That opt-in is captured when you first enable Apple HealthKit or Google Health
                Connect sync; the consent timestamp is recorded server-side so we can honor
                access and audit requests. You can withdraw consent at any time in Settings →
                Privacy &amp; Data, which immediately stops health-data ingestion.
              </p>
              <p>
                <strong>HIPAA note for U.S. users:</strong> FitWiz is a consumer wellness
                application, not a HIPAA-covered entity or business associate. Health information
                you submit is protected by this policy and the CMIA but is not subject to HIPAA.
                Do not submit information obtained from a HIPAA-covered relationship (for
                example, a medical record from your provider) into FitWiz.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                5. Sub-Processors (GDPR Art. 28)
              </h2>
              <p className="mb-4">
                We share your data only with the following sub-processors, each under a written
                data processing agreement. All are located in the United States; transfers from
                the EEA, UK, or Switzerland rely on the European Commission's Standard
                Contractual Clauses (2021/914) and, where applicable, the EU-U.S. Data Privacy
                Framework.
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li><strong className="text-[var(--color-text)]">Supabase Inc.</strong> &mdash; database, authentication, and user data storage.</li>
                <li><strong className="text-[var(--color-text)]">Google Cloud (Vertex AI)</strong> &mdash; model hosting for coach chat, workout generation, food photo analysis, and form video analysis. Zero-retention configuration; no model training on your data.</li>
                <li><strong className="text-[var(--color-text)]">Render Services Inc.</strong> &mdash; backend API hosting (all request traffic passes through Render infrastructure).</li>
                <li><strong className="text-[var(--color-text)]">Vercel Inc.</strong> &mdash; hosts this website (fitwiz.us).</li>
                <li><strong className="text-[var(--color-text)]">Amazon Web Services (S3)</strong> &mdash; storage for food photos and form videos you upload.</li>
                <li><strong className="text-[var(--color-text)]">RevenueCat Inc.</strong> &mdash; subscription and in-app purchase management.</li>
                <li><strong className="text-[var(--color-text)]">Resend, Inc.</strong> &mdash; transactional and lifecycle email delivery.</li>
                <li><strong className="text-[var(--color-text)]">Firebase Cloud Messaging</strong> (Google LLC) &mdash; push notification delivery.</li>
                <li><strong className="text-[var(--color-text)]">Firebase Crashlytics</strong> (Google LLC) &mdash; mobile app crash reporting (90-day retention).</li>
                <li><strong className="text-[var(--color-text)]">Sentry (Functional Software Inc.)</strong> &mdash; backend and mobile error monitoring (90-day retention).</li>
                <li><strong className="text-[var(--color-text)]">PostHog Inc.</strong> (us.i.posthog.com) &mdash; product analytics and feature-flag experiments. Does not receive chat content or health data.</li>
                <li><strong className="text-[var(--color-text)]">ChromaDB Inc.</strong> &mdash; vector database for exercise and workout search.</li>
              </ul>
              <p className="mt-4 text-[13px] text-[var(--color-text-muted)]">
                You can request a copy of the Standard Contractual Clauses in force with any of
                these sub-processors by emailing <a className="text-emerald-400 hover:underline" href="mailto:privacy@fitwiz.app">privacy@fitwiz.app</a>.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                6. Data Security
              </h2>
              <p>
                All traffic between your device and our servers uses TLS/HTTPS. Sensitive data is
                encrypted at rest in our database. We use signed tokens and row-level security
                for authorization, rotate credentials regularly, and restrict access on a
                need-to-know basis. No method of electronic storage is 100% secure and we cannot
                guarantee absolute security, but we will notify affected users without undue
                delay if a breach materially affects their data.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                7. Data Retention
              </h2>
              <ul className="list-disc pl-6 space-y-1">
                <li><strong className="text-[var(--color-text)]">Account &amp; fitness data:</strong> kept while your account is active, deleted on request.</li>
                <li><strong className="text-[var(--color-text)]">Chat history:</strong> up to 12 months, after which a scheduled job automatically deletes transcripts. Turn off "Save chat history" to stop new messages being persisted at all.</li>
                <li><strong className="text-[var(--color-text)]">Health Connect / HealthKit data:</strong> retained only while your account is active.</li>
                <li><strong className="text-[var(--color-text)]">Analytics events (PostHog):</strong> 24 months. Aggregated, non-identifying counts may be retained indefinitely.</li>
                <li><strong className="text-[var(--color-text)]">Crash / error logs (Sentry, Crashlytics):</strong> 90 days.</li>
                <li><strong className="text-[var(--color-text)]">Data-request archives (S3):</strong> auto-deleted 8 days after generation.</li>
              </ul>
              <p className="mt-4">
                When you delete your account, we remove or anonymize personal data within 30
                days, except where retention is required by law.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                8. Your Rights
              </h2>
              <p className="mb-4">Wherever you live, you have the right to:</p>
              <ul className="list-disc pl-6 space-y-1 mb-4">
                <li>Access and download a copy of your data (GDPR Art. 15 / 20)</li>
                <li>Correct inaccurate information</li>
                <li>Delete your account and data (GDPR Art. 17)</li>
                <li>Object to or restrict processing</li>
                <li>Withdraw consent for optional data collection at any time</li>
                <li>Opt out of non-essential notifications and marketing email</li>
                <li>Disconnect Apple HealthKit or Google Health Connect at any time</li>
                <li>Lodge a complaint with your local data protection authority</li>
              </ul>
              <p className="mb-4">You can exercise these rights three ways:</p>
              <ul className="list-disc pl-6 space-y-1">
                <li>
                  <strong className="text-[var(--color-text)]">In the app:</strong>{' '}
                  Settings → Privacy &amp; Data → Export / Delete.
                </li>
                <li>
                  <strong className="text-[var(--color-text)]">Out-of-app (no login required):</strong>{' '}
                  <a href="/data-request" className="text-emerald-400 hover:underline">fitwiz.us/data-request</a> — use
                  this if you cannot sign in. We verify email ownership with a one-time link, then
                  deliver the export or confirm deletion.
                </li>
                <li>
                  <strong className="text-[var(--color-text)]">By email:</strong>{' '}
                  <a href="mailto:privacy@fitwiz.app" className="text-emerald-400 hover:underline">privacy@fitwiz.app</a>.
                </li>
              </ul>
              <p className="mt-4">We respond within 30 days as required by GDPR Art. 12(3) and CCPA &sect; 1798.130.</p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                9. GDPR: DPO and EU / UK Representative
              </h2>
              <p className="mb-4">
                If you are in the EEA, UK, or Switzerland, our designated Data Protection Officer
                can be reached at{' '}
                <a href="mailto:dpo@fitwiz.app" className="text-emerald-400 hover:underline">dpo@fitwiz.app</a>.
                Our Art. 27 representatives are reachable at{' '}
                <a href="mailto:eu-rep@fitwiz.app" className="text-emerald-400 hover:underline">eu-rep@fitwiz.app</a>{' '}
                (EU) and{' '}
                <a href="mailto:uk-rep@fitwiz.app" className="text-emerald-400 hover:underline">uk-rep@fitwiz.app</a>{' '}
                (UK).
              </p>
              <p>
                <strong>Legal bases we rely on:</strong> performance of the subscription contract
                (core workout and coaching features), explicit consent (health data, photos,
                videos, optional marketing), legitimate interests (security, fraud prevention,
                service improvement), and compliance with legal obligations.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                10. CCPA / CPRA (California)
              </h2>
              <p className="mb-4">
                California residents have additional rights: the right to know what categories of
                personal information we collect, the right to delete, the right to correct, and
                the right to opt out of "sale" or "sharing." We do not sell or share personal
                information for cross-context behavioral advertising.
              </p>
              <p>
                Submit California requests through any of the channels in Section 8. We may need
                to verify your identity before fulfilling a request and will never discriminate
                against you for exercising these rights.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                11. Children &amp; Age Requirements
              </h2>
              <p className="mb-4">
                FitWiz is designed for users aged 16 and older. It is not directed at children
                under 16 and we do not knowingly collect personal information from anyone under
                16. This age requirement reflects our processing of sensitive health data,
                automated personalization, and in-app purchases, all of which require a level of
                legal capacity to consent under COPPA, GDPR, and the California Age-Appropriate
                Design Code.
              </p>
              <p>
                If you believe a child under 16 has provided us with personal data, contact{' '}
                <a href="mailto:privacy@fitwiz.app" className="text-emerald-400 hover:underline">privacy@fitwiz.app</a>{' '}
                and we will delete it and the associated account.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                12. International Data Transfers
              </h2>
              <p>
                Our sub-processors are located in the United States. For users in the EEA, UK,
                or Switzerland we rely on the European Commission's Standard Contractual
                Clauses (2021/914) and, where applicable, the EU-U.S. Data Privacy Framework, as
                described in Section 5.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                13. Changes to This Policy
              </h2>
              <p>
                We may update this Privacy Policy from time to time. Material changes will be
                announced in the app and by email where practical, with the "Last updated" date
                above reflecting the effective date.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                14. Contact
              </h2>
              <p className="mb-2"><strong>Data controller:</strong> FitWiz, Inc. (Delaware, USA)</p>
              <p className="mb-2"><strong>Privacy inquiries:</strong>{' '}
                <a href="mailto:privacy@fitwiz.app" className="text-emerald-400 hover:underline">privacy@fitwiz.app</a>
              </p>
              <p className="mb-2"><strong>Data Protection Officer:</strong>{' '}
                <a href="mailto:dpo@fitwiz.app" className="text-emerald-400 hover:underline">dpo@fitwiz.app</a>
              </p>
              <p className="mb-2"><strong>EU / UK Art. 27 Representatives:</strong>{' '}
                <a href="mailto:eu-rep@fitwiz.app" className="text-emerald-400 hover:underline">eu-rep@fitwiz.app</a>{' '}
                &middot;{' '}
                <a href="mailto:uk-rep@fitwiz.app" className="text-emerald-400 hover:underline">uk-rep@fitwiz.app</a>
              </p>
              <p><strong>General support:</strong>{' '}
                <a href="mailto:support@fitwiz.us" className="text-emerald-400 hover:underline">support@fitwiz.us</a>
              </p>
            </div>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
