/**
 * OnboardingSelector Page
 *
 * Entry point for onboarding - lets users choose between:
 * 1. Chat Setup (Primary/Recommended)
 * 2. Traditional Form (Fallback)
 *
 * Features:
 * - Clean, premium aesthetic (Apple Fitness+ / Peloton style)
 * - White/light surfaces
 * - Clear visual hierarchy
 */
import type { FC } from 'react';
import { useNavigate } from 'react-router-dom';

const OnboardingSelector: FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-white flex items-center justify-center px-6 py-10">
      <div className="w-full max-w-lg space-y-8">
        {/* Header */}
        <div className="text-center space-y-3">
          <h1 className="text-4xl font-extrabold text-gray-900 tracking-tight">
            BLive
          </h1>
          <p className="text-lg text-gray-500 font-medium">
            Let's set up your personalized workout plan
          </p>
        </div>

        {/* Selection Cards */}
        <div className="space-y-4">
          {/* Chat Setup Option (Primary) */}
          <button
            onClick={() => navigate('/onboarding/chat')}
            className="
              w-full p-6 rounded-xl border-2 text-left
              bg-gray-900 border-gray-900
              hover:bg-gray-800
              transition-all duration-200 group
            "
          >
            <div className="flex items-center gap-4 mb-3">
              {/* Chat Icon */}
              <div className="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </div>

              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <h2 className="font-bold text-white text-lg">Chat Setup</h2>
                  <span className="bg-white/20 px-2.5 py-0.5 rounded-full text-xs font-semibold text-white uppercase tracking-wide">
                    Recommended
                  </span>
                </div>
                <p className="text-sm text-gray-300">Natural conversation with your coach</p>
              </div>

              {/* Arrow */}
              <svg className="w-5 h-5 text-white/60 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>

            <p className="text-sm text-gray-400 leading-relaxed pl-16">
              Answer questions naturally - no forms, just conversation.
              <span className="text-white/80 font-medium ml-1">Takes ~2 minutes.</span>
            </p>
          </button>

          {/* Divider */}
          <div className="flex items-center gap-4">
            <div className="flex-1 h-px bg-gray-200" />
            <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">
              or
            </span>
            <div className="flex-1 h-px bg-gray-200" />
          </div>

          {/* Traditional Form Option (Secondary) */}
          <button
            onClick={() => navigate('/onboarding')}
            className="
              w-full p-6 rounded-xl border text-left
              bg-white border-gray-200
              hover:bg-gray-50 hover:border-gray-300
              transition-all duration-200 group
            "
          >
            <div className="flex items-center gap-4 mb-3">
              {/* Form Icon */}
              <div className="w-12 h-12 rounded-xl bg-gray-100 flex items-center justify-center">
                <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>

              <div className="flex-1">
                <h2 className="font-bold text-gray-900 text-lg mb-1">Traditional Form</h2>
                <p className="text-sm text-gray-500">Step-by-step questionnaire</p>
              </div>

              {/* Arrow */}
              <svg className="w-5 h-5 text-gray-400 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>

            <p className="text-sm text-gray-500 leading-relaxed pl-16">
              Prefer a classic form? Fill out each section with dropdowns and selections.
            </p>
          </button>
        </div>

        {/* Footer Note */}
        <p className="text-center text-xs text-gray-400">
          Both options collect the same information
        </p>
      </div>
    </div>
  );
};

export default OnboardingSelector;
