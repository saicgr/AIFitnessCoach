import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

export default function HealthDisclaimer() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          <p className="text-[13px] text-[var(--color-text-muted)] mb-4">Last updated: March 7, 2026</p>

          <h1
            className="text-[36px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-8"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Health & Safety Disclaimer
          </h1>

          <div className="space-y-8 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            <div>
              <p>
                Please read this Health & Safety Disclaimer carefully before using the FitWiz mobile application and website (the "Service"). By using FitWiz, you acknowledge that you have read, understood, and agree to be bound by this disclaimer.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                1. Not a Medical Device
              </h2>
              <p>
                FitWiz is a fitness and wellness application. It is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease or medical condition. FitWiz has not been evaluated or approved by any regulatory body as a medical device. The information provided through the Service should not be used as a basis for making medical decisions.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                2. Not Medical Advice
              </h2>
              <p>
                The AI-generated workout plans, nutrition recommendations, and fitness guidance provided by FitWiz are for general informational purposes only. They do not constitute medical advice, professional fitness training, or nutritional counseling. The Service is not a substitute for the advice, diagnosis, or treatment provided by a qualified healthcare professional, certified personal trainer, or registered dietitian.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                3. Consult Your Doctor
              </h2>
              <p className="mb-4">
                You should always consult a qualified healthcare professional before beginning any exercise program, changing your diet, or making decisions that could affect your health. This is especially important if you:
              </p>
              <ul className="list-disc pl-6 space-y-1">
                <li>Have any pre-existing medical conditions (heart disease, diabetes, hypertension, etc.)</li>
                <li>Are pregnant, nursing, or planning to become pregnant</li>
                <li>Have a history of injuries, surgeries, or chronic pain</li>
                <li>Are taking medication that may affect your ability to exercise</li>
                <li>Have not exercised regularly in the past</li>
                <li>Are under 18 or over 65 years of age</li>
              </ul>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                4. Listen to Your Body
              </h2>
              <p className="mb-4">
                While using FitWiz, you should pay close attention to how your body responds to exercise. Stop exercising immediately and seek medical attention if you experience any of the following:
              </p>
              <ul className="list-disc pl-6 space-y-1">
                <li>Chest pain or pressure</li>
                <li>Dizziness, lightheadedness, or fainting</li>
                <li>Severe shortness of breath</li>
                <li>Unusual or sharp pain in muscles, joints, or bones</li>
                <li>Nausea or vomiting during exercise</li>
                <li>Heart palpitations or irregular heartbeat</li>
              </ul>
              <p className="mt-4">
                AI cannot assess your physical condition in real-time. Only you can determine whether an exercise is safe and appropriate for your current physical state.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                5. AI Limitations
              </h2>
              <p>
                FitWiz uses artificial intelligence (Google Gemini) to generate personalized recommendations. While we strive for accuracy and safety, AI-generated content has inherent limitations. Recommendations are advisory in nature, not prescriptions. They may not account for all individual circumstances, physical limitations, or medical conditions. AI models may occasionally produce inaccurate or inappropriate suggestions. Always use your own judgment and consult professionals when in doubt.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                6. Assumption of Risk
              </h2>
              <p>
                Physical exercise carries inherent risks, including but not limited to physical injury, disability, and in rare cases, death. By using FitWiz, you voluntarily assume all risks associated with physical activities performed in connection with the Service. You acknowledge that FitWiz, its developers, affiliates, and partners are not responsible for any injuries, damages, or adverse health outcomes that may result from following AI-generated workout plans or recommendations.
              </p>
            </div>

            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                7. Contact Us
              </h2>
              <p>
                If you have questions about this Health & Safety Disclaimer, please contact us at{' '}
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
