import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useAppStore } from '../store';
import { googleAuth } from '../api/client';
import { extractOnboardingData } from '../types';
import { createLogger } from '../utils/logger';

const log = createLogger('AuthCallback');

export default function AuthCallback() {
  const navigate = useNavigate();
  const { setUser, setSession, setOnboardingData } = useAppStore();
  const [status, setStatus] = useState('Processing sign-in...');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const handleCallback = async () => {
      try {
        log.info('Processing OAuth callback');

        // Get the session from URL hash (Supabase puts tokens there after OAuth redirect)
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();

        if (sessionError) {
          throw sessionError;
        }

        if (!session) {
          throw new Error('No session found after authentication');
        }

        log.info('Session retrieved', { userId: session.user.id });
        setStatus('Authenticating with server...');

        // Store the Supabase session
        setSession(session);

        // Call backend to get/create user in our database
        const { user, backend } = await googleAuth(session.access_token);
        log.info('User authenticated', { userId: user.id, onboarding_completed: user.onboarding_completed });

        // Store user in app state
        setUser(user);

        // Extract and store onboarding data from preferences (for Profile page)
        if (user.onboarding_completed) {
          const onboardingData = extractOnboardingData(backend);
          setOnboardingData(onboardingData);
          log.info('Onboarding data restored from preferences');
        }

        setStatus('Welcome! Redirecting...');

        // Redirect based on onboarding status
        setTimeout(() => {
          if (user.onboarding_completed) {
            navigate('/home', { replace: true });
          } else {
            navigate('/onboarding/chat', { replace: true });
          }
        }, 500);
      } catch (err) {
        log.error('Auth callback failed', err);
        setError(err instanceof Error ? err.message : 'Authentication failed');
      }
    };

    handleCallback();
  }, [navigate, setUser, setSession, setOnboardingData]);

  return (
    <div className="min-h-screen bg-white flex items-center justify-center px-6">
      <div className="max-w-md w-full text-center">
        {error ? (
          <>
            <div className="w-16 h-16 mx-auto mb-6 rounded-full bg-red-50 flex items-center justify-center">
              <svg className="w-8 h-8 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">Authentication Failed</h2>
            <p className="text-gray-500 mb-6">{error}</p>
            <button
              onClick={() => navigate('/login', { replace: true })}
              className="px-6 py-3 rounded-xl bg-gray-900 text-white font-semibold hover:bg-gray-800 transition-all"
            >
              Try Again
            </button>
          </>
        ) : (
          <>
            <div className="w-16 h-16 mx-auto mb-6 rounded-full bg-gray-100 flex items-center justify-center">
              <div className="w-8 h-8 border-3 border-gray-900 border-t-transparent rounded-full animate-spin" />
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">{status}</h2>
            <p className="text-gray-500">Please wait while we set up your account...</p>
          </>
        )}
      </div>
    </div>
  );
}
