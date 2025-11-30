/**
 * OnboardingSelector Page
 *
 * Entry point for onboarding - lets users choose between:
 * 1. AI Chat Setup (Primary/Recommended)
 * 2. Traditional Form (Fallback)
 *
 * Features:
 * - Glass-morphism cards
 * - Gradient animations
 * - Clear visual hierarchy (AI chat is primary)
 */
import { FC } from 'react';
import { useNavigate } from 'react-router-dom';

const OnboardingSelector: FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-background-dark flex items-center justify-center p-4">
      {/* Animated Background Blobs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary/20 rounded-full filter blur-3xl animate-blob"></div>
        <div className="absolute top-1/3 right-1/4 w-96 h-96 bg-secondary/20 rounded-full filter blur-3xl animate-blob animation-delay-2000"></div>
        <div className="absolute bottom-1/4 left-1/3 w-96 h-96 bg-accent/20 rounded-full filter blur-3xl animate-blob animation-delay-4000"></div>
      </div>

      <div className="relative max-w-2xl w-full">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-text mb-2 bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
            Welcome!
          </h1>
          <p className="text-text-secondary">
            Let's set up your personalized workout plan
          </p>
        </div>

        {/* Selection Cards */}
        <div className="space-y-4">
          {/* AI Chat Option (Primary) */}
          <button
            onClick={() => navigate('/onboarding/chat')}
            className="
              w-full p-6 rounded-2xl border-2 text-left
              bg-gradient-to-br from-primary/20 to-secondary/20
              border-primary/50
              hover:border-primary hover:shadow-[0_0_30px_rgba(6,182,212,0.3)]
              transition-all duration-300 group
              transform hover:scale-[1.02]
            "
          >
            <div className="flex items-center gap-4 mb-3">
              {/* AI Icon */}
              <div className="w-14 h-14 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-[0_0_20px_rgba(6,182,212,0.5)] group-hover:shadow-[0_0_30px_rgba(6,182,212,0.7)] transition-all">
                <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                </svg>
              </div>

              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <h2 className="font-bold text-text text-xl">AI Chat Setup</h2>
                  <span className="bg-accent px-3 py-1 rounded-full text-xs font-bold text-white shadow-[0_0_10px_rgba(124,58,237,0.5)]">
                    RECOMMENDED
                  </span>
                </div>
                <p className="text-sm text-text-secondary">Just talk naturally, like chatting with a trainer</p>
              </div>

              {/* Arrow */}
              <svg className="w-6 h-6 text-primary group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>

            <p className="text-sm text-text leading-relaxed pl-[72px]">
              Chat with an AI coach that understands natural language.
              Answer questions your way - no forms, no dropdowns, just conversation.
              <span className="text-primary font-medium ml-1">Takes ~2 minutes.</span>
            </p>
          </button>

          {/* Traditional Form Option (Fallback) */}
          <button
            onClick={() => navigate('/onboarding')}
            className="
              w-full p-6 rounded-2xl border text-left
              bg-white/5 border-white/10
              hover:bg-white/10 hover:border-white/20
              transition-all duration-300
            "
          >
            <div className="flex items-center gap-4 mb-3">
              {/* Form Icon */}
              <div className="w-14 h-14 rounded-xl bg-white/10 flex items-center justify-center">
                <svg className="w-7 h-7 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>

              <div className="flex-1">
                <h2 className="font-bold text-text text-lg mb-1">Traditional Form</h2>
                <p className="text-sm text-text-secondary">Classic step-by-step questionnaire</p>
              </div>

              {/* Arrow */}
              <svg className="w-6 h-6 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>

            <p className="text-sm text-text-secondary leading-relaxed pl-[72px]">
              Prefer a traditional form? Fill out each section at your own pace with dropdowns and selections.
            </p>
          </button>
        </div>

        {/* Footer Note */}
        <p className="text-center text-xs text-text-secondary mt-6 opacity-70">
          Both options collect the same information - choose what feels right for you
        </p>
      </div>
    </div>
  );
};

export default OnboardingSelector;
