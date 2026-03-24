import { useState } from 'react';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

interface FAQItem {
  question: string;
  answer: string;
}

interface FAQCategory {
  title: string;
  items: FAQItem[];
}

const faqData: FAQCategory[] = [
  {
    title: 'Getting Started',
    items: [
      {
        question: 'What is FitWiz?',
        answer:
          'FitWiz is an AI-powered fitness coach that creates personalized workouts, tracks nutrition, and provides real-time coaching — all tailored to your goals, experience level, and available equipment.',
      },
      {
        question: 'Is FitWiz free?',
        answer:
          'Yes, FitWiz has a free tier with core features. Premium is $4.99/month for unlimited workouts, unlimited food scans, full nutrition tracking, advanced analytics, and priority AI coaching.',
      },
      {
        question: 'What devices are supported?',
        answer:
          'FitWiz is currently available on Android (iOS coming soon). A web app is also available at fitwiz.us.',
      },
      {
        question: 'Do I need gym equipment?',
        answer:
          'No, FitWiz creates workouts for any equipment level — including bodyweight only. Just tell us what you have access to during onboarding and the AI will adapt.',
      },
    ],
  },
  {
    title: 'Workouts',
    items: [
      {
        question: 'How does AI generate my workouts?',
        answer:
          "FitWiz uses Google's Gemini AI to generate workouts based on your goals, experience level, available equipment, weekly schedule, and even how you're feeling that day. Every workout is unique to you.",
      },
      {
        question: 'Can I customize my workouts?',
        answer:
          "Yes, you can add or remove exercises, mark favorites with a star, avoid exercises you don't like, and queue specific exercises for your next workout. The AI learns your preferences over time.",
      },
      {
        question: 'What are supersets?',
        answer:
          'Supersets are paired exercises performed back-to-back with minimal rest for greater efficiency. FitWiz automatically detects and groups compatible exercises into supersets within your workout.',
      },
      {
        question: 'Can I modify a workout mid-session?',
        answer:
          'Yes, just ask your AI coach to swap, add, or remove exercises during your workout. The coach will suggest alternatives that fit your current session.',
      },
    ],
  },
  {
    title: 'Nutrition',
    items: [
      {
        question: 'How does food scanning work?',
        answer:
          'Take a photo of your meal or type what you ate. The AI instantly identifies the foods in the image and calculates calories, protein, carbs, and fats — no manual searching required.',
      },
      {
        question: 'Can I scan barcodes?',
        answer:
          'Yes, scan any food barcode for instant nutrition data. The barcode scanner pulls from a comprehensive food database to give you accurate macro and calorie information.',
      },
      {
        question: 'Does FitWiz track water intake?',
        answer:
          'Yes, FitWiz includes hydration tracking with customizable daily goals. The AI hydration agent can also remind you to drink water and adjust targets based on your activity level.',
      },
    ],
  },
  {
    title: 'AI Coach',
    items: [
      {
        question: 'What can I ask the AI coach?',
        answer:
          'Anything about fitness, nutrition, injuries, exercise form, meal suggestions, workout modifications, hydration, and more. The coach uses specialized agents for each domain to give you expert-level answers.',
      },
      {
        question: 'Is the AI personalized to me?',
        answer:
          'Yes, the AI knows your workout history, goals, preferences, injuries, and dietary needs. It adapts its recommendations over time as it learns more about you.',
      },
      {
        question: 'Is my data private?',
        answer:
          'Yes, your data is encrypted and never sold to third parties. We only share data with essential service providers to operate the app. See our Privacy Policy for full details.',
      },
    ],
  },
  {
    title: 'Subscription',
    items: [
      {
        question: 'What does Premium include?',
        answer:
          'Premium unlocks unlimited AI-generated workouts, unlimited food scans, full nutrition tracking with macro breakdowns, advanced analytics and progress charts, and priority AI coaching.',
      },
      {
        question: 'Can I cancel anytime?',
        answer:
          'Yes, you can cancel your subscription at any time through your app store (Google Play). There are no cancellation fees, and you keep Premium access until the end of your billing period.',
      },
      {
        question: 'Is there a free trial?',
        answer:
          'Yes, new users get a 7-day free trial of Premium. You can explore all features before deciding to subscribe.',
      },
    ],
  },
  {
    title: 'Account',
    items: [
      {
        question: 'How do I delete my account?',
        answer:
          'Go to Settings > Privacy & Data > Delete Account within the app. You can also visit fitwiz.us/delete-account to request deletion. Your data will be permanently removed within 30 days.',
      },
      {
        question: 'Can I export my data?',
        answer:
          'Yes, go to Settings > Privacy & Data > Export Data to download a copy of your fitness data, workout history, and nutrition logs.',
      },
      {
        question: 'How do I change my email?',
        answer:
          'Go to Settings > Account to update your email address. You will receive a verification email at your new address to confirm the change.',
      },
    ],
  },
];

function AccordionItem({ question, answer }: FAQItem) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="border-b border-[var(--color-border)]">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="w-full flex items-center justify-between py-4 text-left cursor-pointer"
      >
        <span className="text-[15px] font-medium text-[var(--color-text)] pr-4">{question}</span>
        <svg
          className={`w-5 h-5 text-[var(--color-text-muted)] flex-shrink-0 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2}
        >
          <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      {isOpen && (
        <p className="pb-4 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
          {answer}
        </p>
      )}
    </div>
  );
}

export default function FAQ() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          <h1
            className="text-[36px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Frequently Asked Questions
          </h1>
          <p className="text-[15px] text-[var(--color-text-secondary)] leading-relaxed mb-12">
            Everything you need to know about FitWiz. Can't find an answer? Reach out to us at{' '}
            <a href="mailto:support@fitwiz.app" className="text-emerald-400 hover:underline">
              support@fitwiz.app
            </a>.
          </p>

          <div className="space-y-10">
            {faqData.map((category) => (
              <div key={category.title}>
                <h2
                  className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                  style={{ fontFamily: 'var(--font-heading)' }}
                >
                  {category.title}
                </h2>
                <div>
                  {category.items.map((item) => (
                    <AccordionItem key={item.question} question={item.question} answer={item.answer} />
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
