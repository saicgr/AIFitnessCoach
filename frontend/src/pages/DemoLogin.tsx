import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { login, signup, loginAsDemoUser, generateWorkout } from '../api/client';
import { useAppStore } from '../store';
import { GlassCard, GlassButton } from '../components/ui';
import { createLogger } from '../utils/logger';

const log = createLogger('Login');

type AuthMode = 'login' | 'signup';

export default function DemoLogin() {
  const navigate = useNavigate();
  const { setUser, setOnboardingData } = useAppStore();
  const [mode, setMode] = useState<AuthMode>('login');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<string>('');

  const loginMutation = useMutation({
    mutationFn: async () => {
      setError(null);
      setStatus('Logging in...');
      log.info('Login attempt', { username });
      return await login(username, password);
    },
    onSuccess: (user) => {
      log.info('Login successful', { userId: user.id, onboarding_completed: user.onboarding_completed });
      setUser(user);

      if (user.onboarding_completed) {
        setStatus('Welcome back! Redirecting...');
        setTimeout(() => navigate('/'), 500);
      } else {
        setStatus('Completing your profile...');
        setTimeout(() => navigate('/onboarding'), 500);
      }
    },
    onError: (err: Error & { response?: { data?: { detail?: string } } }) => {
      log.error('Login failed', err);
      setError(err.response?.data?.detail || 'Invalid username or password');
      setStatus('');
    },
  });

  const signupMutation = useMutation({
    mutationFn: async () => {
      setError(null);
      setStatus('Creating account...');
      log.info('Signup attempt', { username, name });
      return await signup(username, password, name || undefined);
    },
    onSuccess: (user) => {
      log.info('Signup successful', { userId: user.id });
      setUser(user);

      // Set name in onboarding data
      if (name) {
        setOnboardingData({ name });
      }

      setStatus('Account created! Setting up your profile...');
      setTimeout(() => navigate('/onboarding'), 500);
    },
    onError: (err: Error & { response?: { data?: { detail?: string } } }) => {
      log.error('Signup failed', err);
      setError(err.response?.data?.detail || 'Failed to create account');
      setStatus('');
    },
  });

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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (mode === 'login') {
      loginMutation.mutate();
    } else {
      signupMutation.mutate();
    }
  };

  const isLoading = loginMutation.isPending || signupMutation.isPending || demoLoginMutation.isPending;

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

        {/* Auth Mode Tabs */}
        <div className="flex rounded-xl bg-white/5 p-1 mb-6">
          <button
            type="button"
            onClick={() => { setMode('login'); setError(null); }}
            className={`flex-1 py-2.5 rounded-lg font-medium text-sm transition-all ${
              mode === 'login'
                ? 'bg-primary text-white shadow-lg'
                : 'text-text-secondary hover:text-text'
            }`}
          >
            Log In
          </button>
          <button
            type="button"
            onClick={() => { setMode('signup'); setError(null); }}
            className={`flex-1 py-2.5 rounded-lg font-medium text-sm transition-all ${
              mode === 'signup'
                ? 'bg-primary text-white shadow-lg'
                : 'text-text-secondary hover:text-text'
            }`}
          >
            Sign Up
          </button>
        </div>

        {/* Login/Signup Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {mode === 'signup' && (
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-2">
                Name (optional)
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Your name"
                className="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-text placeholder-text-muted focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-text-secondary mb-2">
              Username
            </label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Enter username"
              required
              minLength={3}
              className="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-text placeholder-text-muted focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-text-secondary mb-2">
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter password"
              required
              minLength={4}
              className="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-text placeholder-text-muted focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
            />
          </div>

          {error && (
            <div className="p-3 rounded-lg bg-coral/20 border border-coral/30 text-coral text-sm">
              {error}
            </div>
          )}

          <GlassButton
            type="submit"
            fullWidth
            size="lg"
            loading={isLoading}
            disabled={isLoading || !username || !password}
          >
            {isLoading ? status : mode === 'login' ? 'Log In' : 'Create Account'}
          </GlassButton>
        </form>

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

        {/* Demo info */}
        <div className="mt-6 p-4 rounded-xl bg-white/5 border border-white/10">
          <h3 className="text-sm font-semibold text-text mb-2 flex items-center gap-2">
            <svg className="w-4 h-4 text-primary" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
            </svg>
            {mode === 'signup' ? 'What happens next?' : 'Demo Account Features'}
          </h3>
          <ul className="text-xs text-text-muted space-y-1">
            {mode === 'signup' ? (
              <>
                <li>• Create your account with a username</li>
                <li>• Complete a quick onboarding questionnaire</li>
                <li>• Get personalized AI-generated workouts</li>
                <li>• Chat with your AI fitness coach anytime</li>
              </>
            ) : (
              <>
                <li>• Pre-configured intermediate fitness profile</li>
                <li>• 4 workout days per week (Mon, Tue, Thu, Fri)</li>
                <li>• 60-minute push/pull/legs split</li>
                <li>• Full access to AI coach chat</li>
              </>
            )}
          </ul>
        </div>
      </GlassCard>
    </div>
  );
}
