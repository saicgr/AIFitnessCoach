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
        question: 'What exactly is FitWiz?',
        answer:
          'Think of it as a personal trainer, nutritionist, and workout tracker rolled into one app. FitWiz uses AI to build workouts around your goals, track what you eat, and coach you in real time — whether you train at home or in a gym.',
      },
      {
        question: 'How much does it cost?',
        answer:
          'The core app is completely free — you get 1,722 exercises with videos, unlimited workout logging, barcode food scanning, habit tracking, and 5 AI messages a day. Premium is $4.99/month (or $4.17/month billed yearly) and unlocks unlimited AI coaching, photo food logging, AI-generated workouts, and advanced analytics.',
      },
      {
        question: 'Which devices does it work on?',
        answer:
          'FitWiz is available on Android right now, with iOS on the way. You can also access some features through the web app at fitwiz.us.',
      },
      {
        question: 'What if I don\'t have gym equipment?',
        answer:
          'No problem. During onboarding you tell FitWiz what you have access to — even if that\'s nothing — and every workout is built around that. Bodyweight-only plans work great.',
      },
    ],
  },
  {
    title: 'Workouts',
    items: [
      {
        question: 'How are my workouts created?',
        answer:
          'FitWiz uses advanced AI to design each workout based on your goals, fitness level, available equipment, schedule, and even how you\'re feeling that day. No two workouts are the same.',
      },
      {
        question: 'Can I change exercises I don\'t like?',
        answer:
          'Absolutely. Star your favorites, flag exercises you want to avoid, swap mid-workout, or queue specific moves for next time. The AI picks up on your preferences and gets smarter over time.',
      },
      {
        question: 'What are supersets and does FitWiz support them?',
        answer:
          'Supersets pair two exercises back-to-back with minimal rest to save time and boost intensity. FitWiz automatically groups compatible exercises into supersets when it makes sense for your workout.',
      },
      {
        question: 'Can I adjust things during a workout?',
        answer:
          'Yes — just ask your AI coach to swap, add, or drop exercises while you\'re training. It\'ll suggest alternatives that fit the rest of your session.',
      },
    ],
  },
  {
    title: 'Nutrition',
    items: [
      {
        question: 'How does the food photo scanner work?',
        answer:
          'Point your camera at a meal and tap. The AI identifies each food on your plate and gives you a full calorie and macro breakdown in seconds — no searching through databases.',
      },
      {
        question: 'Does it support barcode scanning?',
        answer:
          'Yes. Scan any packaged food barcode and FitWiz pulls the nutrition info instantly from a comprehensive food database.',
      },
      {
        question: 'Can FitWiz help me drink more water?',
        answer:
          'It can. Set a daily hydration goal and the AI will nudge you throughout the day. It also adjusts targets based on how active you\'ve been.',
      },
    ],
  },
  {
    title: 'AI Coach',
    items: [
      {
        question: 'What kind of things can I ask the coach?',
        answer:
          'Pretty much anything fitness-related — exercise form tips, meal ideas, injury modifications, workout swaps, hydration advice, and more. Behind the scenes, specialized AI agents handle each topic so you get genuinely useful answers.',
      },
      {
        question: 'Does the AI actually know my history?',
        answer:
          'Yes. It has context on your past workouts, goals, preferences, injuries, and dietary needs. The longer you use FitWiz, the more personalized the coaching gets.',
      },
      {
        question: 'Is my data safe?',
        answer:
          'Your data is encrypted and never sold. We only share what\'s strictly necessary with service providers to keep the app running. Full details are in our Privacy Policy.',
      },
    ],
  },
  {
    title: 'Subscription',
    items: [
      {
        question: 'What do I get with Premium?',
        answer:
          'Unlimited AI-generated workouts, unlimited photo food logging, full macro tracking, advanced progress charts, muscle heatmaps, voice coaching, and priority AI responses.',
      },
      {
        question: 'Can I cancel whenever I want?',
        answer:
          'Yes, cancel anytime through Google Play. No fees, no hoops. You keep Premium access until the end of your current billing period.',
      },
      {
        question: 'Is there a way to try Premium first?',
        answer:
          'New users get a 7-day free trial with full access to every Premium feature. No payment is required to start — you only get charged if you decide to keep it.',
      },
    ],
  },
  {
    title: 'Account',
    items: [
      {
        question: 'How do I delete my account?',
        answer:
          'Head to Settings > Privacy & Data > Delete Account in the app, or visit fitwiz.us/delete-account. All your data is permanently removed within 30 days.',
      },
      {
        question: 'Can I download a copy of my data?',
        answer:
          'Yes — go to Settings > Privacy & Data > Export Data. You\'ll get a download of your workout history, nutrition logs, and fitness data.',
      },
      {
        question: 'How do I update my email address?',
        answer:
          'Go to Settings > Account and change it there. You\'ll get a verification email at your new address to confirm.',
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
