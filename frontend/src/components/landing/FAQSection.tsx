// Homepage FAQ — full answers in the DOM (crawlable) + FAQPage JSON-LD.

import { FREE_TOOL_COUNT } from '../../lib/toolStats';

const FAQS = [
  {
    q: 'What is Zealova?',
    a: 'Zealova is an AI workout and meal coach for iOS and Android. It generates personalized training plans from your goals and equipment, coaches you in real time during workouts, logs meals from photos, and adapts your program weekly based on what you actually lift and eat.',
  },
  {
    q: 'How is Zealova different from other AI fitness apps?',
    a: 'Most apps do one thing: workout generation, or tracking, or calorie counting. Zealova combines all of them with a coach that has live context. During a workout the AI knows your current exercise, set, and weight, so its answers are specific to the moment, not generic advice.',
  },
  {
    q: 'Is there a free trial?',
    a: 'Yes. Every new account gets a 7-day free trial with all features unlocked. No credit card is required to start. After the trial, Zealova is $7.99/month or $59.99/year.',
  },
  {
    q: 'Does the AI photo food logging actually work?',
    a: 'Point your camera at a meal and Zealova identifies the food, estimates portions, and logs calories plus full macros in seconds. It also scans barcodes, nutrition labels, and restaurant menus. You can always adjust the result before saving.',
  },
  {
    q: 'Can I use Zealova at home without gym equipment?',
    a: 'Yes. Zealova is environment aware: tell it you are training at home, in a hotel, or outdoors and it generates plans using only the equipment you have, including bodyweight-only progressions.',
  },
  {
    q: 'Is Zealova available on iPhone?',
    a: 'Zealova is live on Google Play today. The iOS version is in final preparation; join the waitlist to be notified the day it drops.',
  },
  {
    q: 'Are the free tools really free?',
    a: `Yes. All ${FREE_TOOL_COUNT} browser tools, including the TDEE calculator, 1RM calculator, macro calculator, and the AI workout generator, are free with no signup. They are how we earn your trust before you ever install the app.`,
  },
];

const faqJsonLd = {
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  mainEntity: FAQS.map((f) => ({
    '@type': 'Question',
    name: f.q,
    acceptedAnswer: { '@type': 'Answer', text: f.a },
  })),
};

export default function FAQSection() {
  return (
    <section className="border-t border-white/5 py-24 sm:py-28" aria-labelledby="faq-heading">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
      />
      <div className="mx-auto max-w-[800px] px-6">
        <p className="condensed-kicker mb-4 text-xs text-volt-500">Questions</p>
        <h2 id="faq-heading" className="display-heading mb-10 text-4xl text-white sm:text-5xl">
          Asked and answered
        </h2>

        <div className="space-y-3">
          {FAQS.map((f) => (
            <details
              key={f.q}
              className="group rounded-xl border border-white/10 bg-[#0e0c0a] px-5 py-4"
            >
              <summary className="flex cursor-pointer list-none items-center justify-between text-sm font-medium text-white sm:text-base">
                <span>{f.q}</span>
                <span className="ml-3 text-volt-500 transition-transform group-open:rotate-45">+</span>
              </summary>
              <p className="mt-3 text-sm leading-relaxed text-zinc-400">{f.a}</p>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}
