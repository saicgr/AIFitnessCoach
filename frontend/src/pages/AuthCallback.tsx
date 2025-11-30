import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useAppStore } from '../store';
import { googleAuth } from '../api/client';
import { GlassCard } from '../components/ui';
import { createLogger } from '../utils/logger';

const log = createLogger('AuthCallback');

export default function AuthCallback() {
  const navigate = useNavigate();
  const { setUser, setSession } = useAppStore();
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
        const user = await googleAuth(session.access_token);
        log.info('User authenticated', { userId: user.id, onboarding_completed: user.onboarding_completed });

        // Store user in app state
        setUser(user);

        setStatus('Welcome! Redirecting...');

        // Redirect based on onboarding status
        setTimeout(() => {
          if (user.onboarding_completed) {
            navigate('/', { replace: true });
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
  }, [navigate, setUser, setSession]);

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      {/* Background gradient effects */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-primary/20 rounded-full blur-[100px]" />
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-accent/20 rounded-full blur-[100px]" />
      </div>

      <GlassCard variant="elevated" className="max-w-md w-full p-8 relative z-10 text-center">
        {error ? (
          <>
            <div className="w-16 h-16 mx-auto mb-6 rounded-full bg-coral/20 flex items-center justify-center">
              <svg className="w-8 h-8 text-coral" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <h2 className="text-xl font-semibold text-text mb-2">Authentication Failed</h2>
            <p className="text-text-secondary mb-6">{error}</p>
            <button
              onClick={() => navigate('/login', { replace: true })}
              className="px-6 py-2 rounded-lg bg-primary text-white font-medium hover:bg-primary/90 transition-colors"
            >
              Try Again
            </button>
          </>
        ) : (
          <>
            <div className="w-16 h-16 mx-auto mb-6 rounded-full bg-primary/20 flex items-center justify-center">
              <div className="w-8 h-8 border-3 border-primary border-t-transparent rounded-full animate-spin" />
            </div>
            <h2 className="text-xl font-semibold text-text mb-2">{status}</h2>
            <p className="text-text-secondary">Please wait while we set up your account...</p>
          </>
        )}
      </GlassCard>
    </div>
  );
}
