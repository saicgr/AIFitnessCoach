import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { loginAsDemoUser, generateWorkout } from '../api/client';
import { useAppStore } from '../store';
import { GlassCard, GlassButton } from '../components/ui';
import { supabase } from '../lib/supabase';
import { createLogger } from '../utils/logger';

const log = createLogger('Login');

export default function DemoLogin() {
  const navigate = useNavigate();
  const { setUser } = useAppStore();
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<string>('');
  const [isGoogleLoading, setIsGoogleLoading] = useState(false);

  const handleGoogleSignIn = async () => {
    try {
      setError(null);
      setIsGoogleLoading(true);
      setStatus('Redirecting to Google...');
      log.info('Initiating Google sign-in');

      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/auth/callback`,
        },
      });

      if (error) {
        throw error;
      }
    } catch (err) {
      log.error('Google sign-in failed', err);
      setError(err instanceof Error ? err.message : 'Failed to sign in with Google');
      setStatus('');
      setIsGoogleLoading(false);
    }
  };

  const demoLoginMutation = useMutation({
    mutationFn: async () => {
      setError(null);
      setStatus('Creating demo account...');
      log.info('Logging in as demo user');

      const user = await loginAsDemoUser();
      log.info('Demo user retrieved', { userId: user.id });

      setStatus('Setting up your workout...');

      try {
        await generateWorkout({
          user_id: user.id,
          duration_minutes: 60,
          fitness_level: user.fitness_level,
          goals: user.goals,
          equipment: user.equipment,
        });
        log.info('Demo workout generated');
      } catch {
        log.info('Workout generation skipped (may already exist)');
      }

      return user;
    },
    onSuccess: (user) => {
      setUser(user);
      setStatus('Welcome! Redirecting...');
      log.info('Demo login successful, redirecting to home');
      setTimeout(() => navigate('/'), 500);
    },
    onError: (error) => {
      log.error('Demo login failed', error);
      setError('Failed to create demo account. Make sure the backend is running.');
      setStatus('');
    },
  });

  const isLoading = isGoogleLoading || demoLoginMutation.isPending;

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      {/* Background gradient effects */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-primary/20 rounded-full blur-[100px]" />
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-accent/20 rounded-full blur-[100px]" />
      </div>

      <GlassCard variant="elevated" className="max-w-md w-full p-8 relative z-10">
        <div className="text-center mb-8">
          {/* Logo/Icon */}
          <div className="w-20 h-20 mx-auto mb-6 rounded-2xl bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-[0_0_30px_rgba(6,182,212,0.4)]">
            <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>

          <h1 className="text-3xl font-bold text-text mb-2">AI Fitness Coach</h1>
          <p className="text-text-secondary">Your personal AI-powered workout companion</p>
        </div>

        {error && (
          <div className="mb-6 p-3 rounded-lg bg-coral/20 border border-coral/30 text-coral text-sm">
            {error}
          </div>
        )}

        {status && (
          <div className="mb-6 p-3 rounded-lg bg-primary/20 border border-primary/30 text-primary text-sm text-center">
            {status}
          </div>
        )}

        {/* Google Sign In Button */}
        <button
          onClick={handleGoogleSignIn}
          disabled={isLoading}
          className="w-full flex items-center justify-center gap-3 px-4 py-3 rounded-xl bg-white text-gray-700 font-medium hover:bg-gray-50 transition-all shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isGoogleLoading ? (
            <div className="w-5 h-5 border-2 border-gray-300 border-t-gray-700 rounded-full animate-spin" />
          ) : (
            <svg className="w-5 h-5" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
              />
            </svg>
          )}
          {isGoogleLoading ? 'Signing in...' : 'Continue with Google'}
        </button>

        <div className="relative my-6">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-white/10" />
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="px-2 bg-surface text-text-muted">or</span>
          </div>
        </div>

        <GlassButton
          fullWidth
          size="lg"
          variant="secondary"
          onClick={() => demoLoginMutation.mutate()}
          loading={demoLoginMutation.isPending}
          disabled={isLoading}
        >
          {demoLoginMutation.isPending ? status : 'Try Demo Account'}
        </GlassButton>

        {/* Info section */}
        <div className="mt-6 p-4 rounded-xl bg-white/5 border border-white/10">
          <h3 className="text-sm font-semibold text-text mb-2 flex items-center gap-2">
            <svg className="w-4 h-4 text-primary" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
            </svg>
            What you'll get
          </h3>
          <ul className="text-xs text-text-muted space-y-1">
            <li>• Personalized AI-generated workout plans</li>
            <li>• Real-time chat with your AI fitness coach</li>
            <li>• Progress tracking and workout history</li>
            <li>• Custom workout scheduling</li>
          </ul>
        </div>
      </GlassCard>
    </div>
  );
}
