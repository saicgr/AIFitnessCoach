import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { useAppStore, clearAppStorage } from '../store';
import { resetUser, getActiveInjuries, sendTestEmail, saveNotificationSettings } from '../api/client';
import { createLogger } from '../utils/logger';
import type { ActiveInjury } from '../types';
import { GlassCard, GlassButton, ProgressBar } from '../components/ui';
import { DashboardLayout } from '../components/layout';

const log = createLogger('settings');

// Icon components
const Icons = {
  Back: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
    </svg>
  ),
  Target: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
    </svg>
  ),
  Warning: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
    </svg>
  ),
  Trash: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
    </svg>
  ),
  Info: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
  Logout: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
    </svg>
  ),
  Bandage: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
  ),
  Sun: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
  ),
  Moon: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
    </svg>
  ),
  Bell: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
    </svg>
  ),
  BellOff: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11M6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9M18 11a6 6 0 00-6-6M9 7a6 6 0 00-3 5.197M3 3l18 18" />
    </svg>
  ),
  Email: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
    </svg>
  ),
  Chart: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
    </svg>
  ),
  Food: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
    </svg>
  ),
  Sparkles: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
    </svg>
  ),
  Check: () => (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
    </svg>
  ),
  Water: () => (
    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 21c4.418 0 8-3.134 8-7 0-4.418-8-11-8-11S4 9.582 4 14c0 3.866 3.582 7 8 7z" />
    </svg>
  ),
};

// Section Header component
function SectionHeader({ icon, title, subtitle }: { icon: React.ReactNode; title: string; subtitle?: string }) {
  return (
    <div className="flex items-center gap-3 mb-4">
      <div className="p-2 bg-primary/20 rounded-xl text-primary">
        {icon}
      </div>
      <div>
        <h2 className="text-lg font-semibold text-text">{title}</h2>
        {subtitle && <p className="text-xs text-text-secondary">{subtitle}</p>}
      </div>
    </div>
  );
}

// Chip component
function Chip({ children, variant = 'primary' }: { children: React.ReactNode; variant?: 'primary' | 'secondary' }) {
  const classes = {
    primary: 'bg-primary/20 text-primary border-primary/30',
    secondary: 'bg-accent/20 text-accent border-accent/30',
  };

  return (
    <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium border ${classes[variant]}`}>
      {children}
    </span>
  );
}

export default function Settings() {
  const navigate = useNavigate();
  const {
    user,
    onboardingData,
    theme,
    toggleTheme,
    setUser,
    notificationSettings,
    setNotificationSettings,
    setIncludedInSummary,
    setFoodTrackingMeals,
    toggleSummaryEmailFrequency,
  } = useAppStore();
  const [showResetDialog, setShowResetDialog] = useState(false);
  const [resetError, setResetError] = useState<string | null>(null);
  const [activeInjuries, setActiveInjuries] = useState<ActiveInjury[]>([]);
  const [injuriesLoading, setInjuriesLoading] = useState(false);
  const [testEmailSending, setTestEmailSending] = useState(false);
  const [testEmailResult, setTestEmailResult] = useState<{ success: boolean; message: string } | null>(null);

  // Handle test email
  const handleSendTestEmail = async () => {
    if (!user) return;

    // Get user email from session (Google auth provides this)
    const { session } = useAppStore.getState();
    const email = session?.user?.email;

    if (!email) {
      setTestEmailResult({ success: false, message: 'No email address found. Please log in with Google to use email features.' });
      return;
    }

    setTestEmailSending(true);
    setTestEmailResult(null);

    try {
      const result = await sendTestEmail(email);
      setTestEmailResult({ success: true, message: `Test email sent to ${email}` });
      log.info('Test email sent', result);
    } catch (error: any) {
      const message = error.response?.data?.detail || error.message || 'Failed to send test email';
      setTestEmailResult({ success: false, message });
      log.error('Test email failed', error);
    } finally {
      setTestEmailSending(false);
    }
  };

  // Fetch active injuries
  useEffect(() => {
    const fetchInjuries = async () => {
      if (!user) return;

      setInjuriesLoading(true);
      try {
        const injuries = await getActiveInjuries(user.id);
        setActiveInjuries(injuries);
        log.info('Active injuries fetched', injuries);
      } catch (error) {
        log.error('Failed to fetch injuries', error);
      } finally {
        setInjuriesLoading(false);
      }
    };

    fetchInjuries();
  }, [user]);

  // Sync notification settings to backend when they change
  useEffect(() => {
    const syncSettings = async () => {
      if (!user) return;

      try {
        await saveNotificationSettings(String(user.id), notificationSettings);
        log.info('Notification settings synced to backend');
      } catch (error) {
        log.error('Failed to sync notification settings', error);
      }
    };

    // Debounce the sync to avoid too many API calls
    const timeoutId = setTimeout(syncSettings, 1000);
    return () => clearTimeout(timeoutId);
  }, [user, notificationSettings]);


  const resetMutation = useMutation({
    mutationFn: async () => {
      if (!user) throw new Error('No user found');
      log.info('Starting full reset for user', { userId: user.id });
      await resetUser(user.id);
      log.info('Backend reset successful');
    },
    onSuccess: () => {
      log.info('Reset successful, clearing local storage');
      clearAppStorage();
      navigate('/login', { replace: true });
    },
    onError: (error: Error) => {
      log.error('Reset failed', error);
      setResetError(error.message || 'Failed to reset data. Please try again.');
    },
  });

  const handleResetClick = () => {
    setResetError(null);
    setShowResetDialog(true);
  };

  const handleConfirmReset = () => {
    resetMutation.mutate();
  };

  const handleCancelReset = () => {
    setShowResetDialog(false);
    setResetError(null);
  };

  if (!user) {
    navigate('/login');
    return null;
  }

  const userInitials = onboardingData.name
    ? onboardingData.name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
    : 'U';

  return (
    <DashboardLayout>
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Profile Card */}
        <div
          className="relative overflow-hidden rounded-2xl p-6 bg-gradient-to-br from-primary to-secondary"
          style={{
            boxShadow: '0 0 40px rgba(6, 182, 212, 0.3), 0 20px 40px rgba(0,0,0,0.3)',
          }}
        >
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-white/20 backdrop-blur rounded-2xl flex items-center justify-center text-xl font-bold text-white">
              {userInitials}
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-white">{onboardingData.name || 'Fitness Enthusiast'}</h2>
              <p className="text-white/70 text-sm capitalize">{user.fitness_level} Level</p>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3 mt-6">
            <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
              <p className="text-2xl font-bold text-white">{onboardingData.age}</p>
              <p className="text-xs text-white/70">Age</p>
            </div>
            <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
              <p className="text-2xl font-bold text-white">{onboardingData.weightKg}</p>
              <p className="text-xs text-white/70">kg</p>
            </div>
            <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
              <p className="text-2xl font-bold text-white">{onboardingData.heightCm}</p>
              <p className="text-xs text-white/70">cm</p>
            </div>
          </div>
        </div>

        {/* Appearance Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={theme === 'dark' ? <Icons.Moon /> : <Icons.Sun />}
            title="Appearance"
            subtitle="Customize your experience"
          />

          <div className="flex items-center justify-between py-3">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-white/5 rounded-xl">
                {theme === 'dark' ? <Icons.Moon /> : <Icons.Sun />}
              </div>
              <div>
                <p className="font-medium text-text">Dark Mode</p>
                <p className="text-xs text-text-secondary">
                  {theme === 'dark' ? 'Currently using dark theme' : 'Currently using light theme'}
                </p>
              </div>
            </div>

            {/* Toggle Switch */}
            <button
              onClick={toggleTheme}
              className={`relative w-14 h-8 rounded-full transition-all duration-300 ${
                theme === 'dark'
                  ? 'bg-primary shadow-[0_0_15px_rgba(6,182,212,0.4)]'
                  : 'bg-white/20 border border-white/30'
              }`}
            >
              <div
                className={`absolute top-1 w-6 h-6 rounded-full transition-all duration-300 flex items-center justify-center ${
                  theme === 'dark'
                    ? 'left-7 bg-white text-primary'
                    : 'left-1 bg-white text-orange'
                }`}
              >
                {theme === 'dark' ? (
                  <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                  </svg>
                ) : (
                  <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
                  </svg>
                )}
              </div>
            </button>
          </div>
        </GlassCard>

        {/* Notifications Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={<Icons.Bell />}
            title="Notifications"
            subtitle="Manage how you receive updates"
          />

          <div className="space-y-6">
            {/* Channel Preferences */}
            <div className="space-y-3">
              <p className="text-xs font-medium text-text-secondary uppercase tracking-wide">Notification Channels</p>

              {/* Email Toggle */}
              <div className="flex items-center justify-between py-2">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-white/5 rounded-xl">
                    <Icons.Email />
                  </div>
                  <div>
                    <p className="font-medium text-text">Email Notifications</p>
                    <p className="text-xs text-text-secondary">Receive updates via email</p>
                  </div>
                </div>
                <button
                  onClick={() => setNotificationSettings({ emailEnabled: !notificationSettings.emailEnabled })}
                  className={`relative w-14 h-8 rounded-full transition-all duration-300 ${
                    notificationSettings.emailEnabled
                      ? 'bg-primary shadow-[0_0_15px_rgba(6,182,212,0.4)]'
                      : 'bg-white/20 border border-white/30'
                  }`}
                >
                  <div className={`absolute top-1 w-6 h-6 rounded-full transition-all duration-300 bg-white ${
                    notificationSettings.emailEnabled ? 'left-7' : 'left-1'
                  }`} />
                </button>
              </div>

              {/* Push Toggle */}
              <div className="flex items-center justify-between py-2">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-white/5 rounded-xl">
                    <Icons.Bell />
                  </div>
                  <div>
                    <p className="font-medium text-text">Push Notifications</p>
                    <p className="text-xs text-text-secondary">Browser/app notifications</p>
                  </div>
                </div>
                <button
                  onClick={() => setNotificationSettings({ pushEnabled: !notificationSettings.pushEnabled })}
                  className={`relative w-14 h-8 rounded-full transition-all duration-300 ${
                    notificationSettings.pushEnabled
                      ? 'bg-primary shadow-[0_0_15px_rgba(6,182,212,0.4)]'
                      : 'bg-white/20 border border-white/30'
                  }`}
                >
                  <div className={`absolute top-1 w-6 h-6 rounded-full transition-all duration-300 bg-white ${
                    notificationSettings.pushEnabled ? 'left-7' : 'left-1'
                  }`} />
                </button>
              </div>
            </div>

            {/* Workout Reminders - only show if email enabled */}
            {notificationSettings.emailEnabled && (
              <>
                <div className="border-t border-white/10 pt-4">
                  <p className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-3">Workout Reminders</p>
                  <div className="grid grid-cols-3 gap-2">
                    {[
                      { value: 'none', label: 'Off' },
                      { value: 'workout_days', label: 'Workout Days' },
                      { value: 'daily', label: 'Daily' },
                    ].map((option) => (
                      <button
                        key={option.value}
                        onClick={() => setNotificationSettings({ workoutReminderFrequency: option.value as 'none' | 'workout_days' | 'daily' })}
                        className={`px-3 py-2.5 rounded-xl text-sm font-medium transition-all ${
                          notificationSettings.workoutReminderFrequency === option.value
                            ? 'bg-primary text-white shadow-[0_0_15px_rgba(6,182,212,0.3)]'
                            : 'bg-white/5 text-text-secondary hover:bg-white/10 border border-white/10'
                        }`}
                      >
                        {option.label}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Summary Emails - Multi-select */}
                <div className="border-t border-white/10 pt-4">
                  <div className="flex items-center gap-2 mb-3">
                    <Icons.Chart />
                    <div>
                      <p className="text-xs font-medium text-text-secondary uppercase tracking-wide">Progress Summary Emails</p>
                      <p className="text-xs text-text-muted mt-0.5">Select multiple frequencies</p>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2">
                    {[
                      { value: 'weekly' as const, label: 'Weekly' },
                      { value: 'monthly' as const, label: 'Monthly' },
                      { value: '3_months' as const, label: '3 Months' },
                      { value: '6_months' as const, label: '6 Months' },
                      { value: '12_months' as const, label: 'Yearly' },
                    ].map((option) => {
                      const frequencies = notificationSettings.summaryEmailFrequencies || [];
                      const isSelected = frequencies.includes(option.value);
                      return (
                        <button
                          key={option.value}
                          onClick={() => toggleSummaryEmailFrequency(option.value)}
                          className={`flex items-center gap-2 px-3 py-2.5 rounded-xl text-sm font-medium transition-all ${
                            isSelected
                              ? 'bg-primary text-white shadow-[0_0_15px_rgba(6,182,212,0.3)]'
                              : 'bg-white/5 text-text-secondary hover:bg-white/10 border border-white/10'
                          }`}
                        >
                          {isSelected && <Icons.Check />}
                          {option.label}
                        </button>
                      );
                    })}
                  </div>

                  {/* Summary Content Options - show if any frequency selected */}
                  {(notificationSettings.summaryEmailFrequencies || []).length > 0 && (
                    <div className="mt-4 space-y-2">
                      <p className="text-xs text-text-muted mb-2">Include in summary:</p>
                      <div className="flex flex-wrap gap-2">
                        <button
                          onClick={() => setIncludedInSummary({ workoutData: !notificationSettings.includedInSummary.workoutData })}
                          className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm transition-all ${
                            notificationSettings.includedInSummary.workoutData
                              ? 'bg-accent/20 text-accent border border-accent/30'
                              : 'bg-white/5 text-text-secondary border border-white/10'
                          }`}
                        >
                          {notificationSettings.includedInSummary.workoutData && <Icons.Check />}
                          Workout Data
                        </button>
                        <button
                          onClick={() => setIncludedInSummary({ weightData: !notificationSettings.includedInSummary.weightData })}
                          className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm transition-all ${
                            notificationSettings.includedInSummary.weightData
                              ? 'bg-accent/20 text-accent border border-accent/30'
                              : 'bg-white/5 text-text-secondary border border-white/10'
                          }`}
                        >
                          {notificationSettings.includedInSummary.weightData && <Icons.Check />}
                          Weight Data
                        </button>
                      </div>
                    </div>
                  )}
                </div>

                {/* Food Tracking Emails */}
                <div className="border-t border-white/10 pt-4">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <Icons.Food />
                      <p className="text-xs font-medium text-text-secondary uppercase tracking-wide">Food Tracking Emails</p>
                    </div>
                    <button
                      onClick={() => setNotificationSettings({ foodTrackingEnabled: !notificationSettings.foodTrackingEnabled })}
                      className={`relative w-12 h-6 rounded-full transition-all duration-300 ${
                        notificationSettings.foodTrackingEnabled
                          ? 'bg-primary'
                          : 'bg-white/20 border border-white/30'
                      }`}
                    >
                      <div className={`absolute top-0.5 w-5 h-5 rounded-full transition-all duration-300 bg-white ${
                        notificationSettings.foodTrackingEnabled ? 'left-6' : 'left-0.5'
                      }`} />
                    </button>
                  </div>

                  {notificationSettings.foodTrackingEnabled && (
                    <div className="space-y-2">
                      <p className="text-xs text-text-muted mb-2">Request food photos for:</p>
                      <div className="flex flex-wrap gap-2">
                        {(['breakfast', 'lunch', 'dinner'] as const).map((meal) => (
                          <button
                            key={meal}
                            onClick={() => setFoodTrackingMeals({ [meal]: !notificationSettings.foodTrackingMeals[meal] })}
                            className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm capitalize transition-all ${
                              notificationSettings.foodTrackingMeals[meal]
                                ? 'bg-accent/20 text-accent border border-accent/30'
                                : 'bg-white/5 text-text-secondary border border-white/10'
                            }`}
                          >
                            {notificationSettings.foodTrackingMeals[meal] && <Icons.Check />}
                            {meal}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {/* Motivation Emails */}
                <div className="border-t border-white/10 pt-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-white/5 rounded-xl">
                        <Icons.Sparkles />
                      </div>
                      <div>
                        <p className="font-medium text-text">Motivation Emails</p>
                        <p className="text-xs text-text-secondary">Receive encouragement and tips</p>
                      </div>
                    </div>
                    <button
                      onClick={() => setNotificationSettings({ motivationEmailsEnabled: !notificationSettings.motivationEmailsEnabled })}
                      className={`relative w-14 h-8 rounded-full transition-all duration-300 ${
                        notificationSettings.motivationEmailsEnabled
                          ? 'bg-primary shadow-[0_0_15px_rgba(6,182,212,0.4)]'
                          : 'bg-white/20 border border-white/30'
                      }`}
                    >
                      <div className={`absolute top-1 w-6 h-6 rounded-full transition-all duration-300 bg-white ${
                        notificationSettings.motivationEmailsEnabled ? 'left-7' : 'left-1'
                      }`} />
                    </button>
                  </div>
                </div>

                {/* Test Email Button */}
                <div className="border-t border-white/10 pt-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-white/5 rounded-xl">
                        <Icons.Email />
                      </div>
                      <div>
                        <p className="font-medium text-text">Test Email</p>
                        <p className="text-xs text-text-secondary">Send a test email to verify delivery</p>
                      </div>
                    </div>
                    <button
                      onClick={handleSendTestEmail}
                      disabled={testEmailSending}
                      className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                        testEmailSending
                          ? 'bg-white/10 text-text-muted cursor-not-allowed'
                          : 'bg-primary/20 text-primary hover:bg-primary/30 border border-primary/30'
                      }`}
                    >
                      {testEmailSending ? 'Sending...' : 'Send Test'}
                    </button>
                  </div>
                  {testEmailResult && (
                    <div className={`mt-3 p-3 rounded-xl text-sm ${
                      testEmailResult.success
                        ? 'bg-accent/10 text-accent border border-accent/30'
                        : 'bg-coral/10 text-coral border border-coral/30'
                    }`}>
                      {testEmailResult.message}
                    </div>
                  )}
                </div>
              </>
            )}
          </div>
        </GlassCard>

        {/* Hydration Settings Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={<Icons.Water />}
            title="Hydration"
            subtitle="Stay hydrated during workouts"
          />

          <div className="space-y-4">
            {/* Hydration Reminders Toggle */}
            <div className="flex items-center justify-between py-2">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-500/10 rounded-xl">
                  <Icons.Bell />
                </div>
                <div>
                  <p className="font-medium text-text">Workout Reminders</p>
                  <p className="text-xs text-text-secondary">Get reminded to drink during workouts</p>
                </div>
              </div>
              <button
                onClick={() => setNotificationSettings({ hydrationRemindersEnabled: !notificationSettings.hydrationRemindersEnabled })}
                className={`relative w-14 h-8 rounded-full transition-all duration-300 ${
                  notificationSettings.hydrationRemindersEnabled
                    ? 'bg-blue-500 shadow-[0_0_15px_rgba(59,130,246,0.4)]'
                    : 'bg-white/20 border border-white/30'
                }`}
              >
                <div className={`absolute top-1 w-6 h-6 rounded-full transition-all duration-300 bg-white ${
                  notificationSettings.hydrationRemindersEnabled ? 'left-7' : 'left-1'
                }`} />
              </button>
            </div>

            {/* Reminder Interval - only show if reminders enabled */}
            {notificationSettings.hydrationRemindersEnabled && (
              <div className="border-t border-white/10 pt-4">
                <p className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-3">Reminder Interval</p>
                <div className="grid grid-cols-4 gap-2">
                  {([30, 45, 60, 90] as const).map((minutes) => (
                    <button
                      key={minutes}
                      onClick={() => setNotificationSettings({ hydrationReminderInterval: minutes })}
                      className={`px-3 py-2.5 rounded-xl text-sm font-medium transition-all ${
                        notificationSettings.hydrationReminderInterval === minutes
                          ? 'bg-blue-500 text-white shadow-[0_0_15px_rgba(59,130,246,0.3)]'
                          : 'bg-white/5 text-text-secondary hover:bg-white/10 border border-white/10'
                      }`}
                    >
                      {minutes}m
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Daily Goal */}
            <div className="border-t border-white/10 pt-4">
              <div className="flex items-center justify-between mb-3">
                <p className="text-xs font-medium text-text-secondary uppercase tracking-wide">Daily Goal</p>
                {/* Unit Toggle */}
                <button
                  onClick={() => setNotificationSettings({
                    hydrationUnit: notificationSettings.hydrationUnit === 'oz' ? 'ml' : 'oz'
                  })}
                  className="text-xs px-2 py-1 rounded bg-white/10 hover:bg-white/15 text-text-muted transition-colors"
                >
                  {notificationSettings.hydrationUnit?.toUpperCase() || 'OZ'}
                </button>
              </div>
              <div className="grid grid-cols-4 gap-2">
                {[
                  { ml: 2000, oz: 68 },
                  { ml: 2500, oz: 85 },
                  { ml: 3000, oz: 101 },
                  { ml: 3500, oz: 118 },
                ].map((goal) => {
                  const displayValue = notificationSettings.hydrationUnit === 'ml' ? goal.ml : goal.oz;
                  const unit = notificationSettings.hydrationUnit === 'ml' ? 'ml' : 'oz';
                  const isSelected = notificationSettings.hydrationDailyGoalMl === goal.ml;
                  return (
                    <button
                      key={goal.ml}
                      onClick={() => setNotificationSettings({ hydrationDailyGoalMl: goal.ml })}
                      className={`px-2 py-2.5 rounded-xl text-sm font-medium transition-all ${
                        isSelected
                          ? 'bg-blue-500 text-white shadow-[0_0_15px_rgba(59,130,246,0.3)]'
                          : 'bg-white/5 text-text-secondary hover:bg-white/10 border border-white/10'
                      }`}
                    >
                      {displayValue}{unit}
                    </button>
                  );
                })}
              </div>
              <p className="text-xs text-text-muted mt-2">
                {notificationSettings.hydrationUnit === 'ml'
                  ? `${notificationSettings.hydrationDailyGoalMl || 2500}ml per day`
                  : `${Math.round((notificationSettings.hydrationDailyGoalMl || 2500) / 29.574)}oz per day`
                }
              </p>
            </div>
          </div>
        </GlassCard>

        {/* Weekly Summary Section */}
        <GlassCard className="p-6">
          <SectionHeader
            icon={<Icons.Sparkles />}
            title="Weekly Summary"
            subtitle="AI-generated workout reports"
          />

          <div className="space-y-4">
            {/* Weekly Summary Toggle */}
            <div className="flex items-center justify-between py-2">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-purple-500/10 rounded-xl">
                  <Icons.Email />
                </div>
                <div>
                  <p className="font-medium text-text">Weekly Summary Emails</p>
                  <p className="text-xs text-text-secondary">Get AI-powered workout summaries</p>
                </div>
              </div>
              <button
                onClick={() => {
                  const isEnabled = notificationSettings.summaryEmailFrequencies?.includes('weekly');
                  if (isEnabled) {
                    setNotificationSettings({
                      summaryEmailFrequencies: notificationSettings.summaryEmailFrequencies?.filter(f => f !== 'weekly') || []
                    });
                  } else {
                    setNotificationSettings({
                      summaryEmailFrequencies: [...(notificationSettings.summaryEmailFrequencies || []), 'weekly']
                    });
                  }
                }}
                className={`relative w-14 h-8 rounded-full transition-all duration-300 ${
                  notificationSettings.summaryEmailFrequencies?.includes('weekly')
                    ? 'bg-purple-500 shadow-[0_0_15px_rgba(168,85,247,0.4)]'
                    : 'bg-white/20 border border-white/30'
                }`}
              >
                <div className={`absolute top-1 w-6 h-6 rounded-full transition-all duration-300 bg-white ${
                  notificationSettings.summaryEmailFrequencies?.includes('weekly') ? 'left-7' : 'left-1'
                }`} />
              </button>
            </div>

            {/* What's included */}
            {notificationSettings.summaryEmailFrequencies?.includes('weekly') && (
              <div className="border-t border-white/10 pt-4">
                <p className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-3">Summary Includes</p>
                <div className="space-y-2">
                  {[
                    { label: 'Workout stats & completion', icon: '📊', always: true },
                    { label: 'AI-generated highlights', icon: '✨', always: true },
                    { label: 'Personal records achieved', icon: '🏆', always: true },
                    { label: 'Motivational message', icon: '💪', always: true },
                    { label: 'Tips for next week', icon: '💡', always: true },
                  ].map((item) => (
                    <div key={item.label} className="flex items-center gap-2 text-sm text-text-muted">
                      <span>{item.icon}</span>
                      <span>{item.label}</span>
                      {item.always && <Icons.Check />}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Achievement Notifications */}
            <div className="border-t border-white/10 pt-4">
              <div className="flex items-center justify-between py-2">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-yellow-500/10 rounded-xl text-yellow-400">
                    <Icons.Sparkles />
                  </div>
                  <div>
                    <p className="font-medium text-text">Achievement Alerts</p>
                    <p className="text-xs text-text-secondary">Get notified when you earn achievements</p>
                  </div>
                </div>
                <button
                  onClick={() => setNotificationSettings({ motivationEmailsEnabled: !notificationSettings.motivationEmailsEnabled })}
                  className={`relative w-14 h-8 rounded-full transition-all duration-300 ${
                    notificationSettings.motivationEmailsEnabled
                      ? 'bg-yellow-500 shadow-[0_0_15px_rgba(234,179,8,0.4)]'
                      : 'bg-white/20 border border-white/30'
                  }`}
                >
                  <div className={`absolute top-1 w-6 h-6 rounded-full transition-all duration-300 bg-white ${
                    notificationSettings.motivationEmailsEnabled ? 'left-7' : 'left-1'
                  }`} />
                </button>
              </div>
            </div>
          </div>
        </GlassCard>

        {/* Goals & Equipment Section */}
        <GlassCard className="p-6">
          <SectionHeader icon={<Icons.Target />} title="Goals & Equipment" />

          <div className="space-y-4">
            <div>
              <p className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-2">Your Goals</p>
              <div className="flex flex-wrap gap-2">
                {user.goals.length > 0 ? (
                  user.goals.map((goal) => (
                    <Chip key={goal} variant="primary">{goal}</Chip>
                  ))
                ) : (
                  <span className="text-text-muted text-sm">No goals set</span>
                )}
              </div>
            </div>

            <div className="border-t border-white/10 pt-4">
              <p className="text-xs font-medium text-text-secondary uppercase tracking-wide mb-2">Available Equipment</p>
              <div className="flex flex-wrap gap-2">
                {user.equipment.length > 0 ? (
                  user.equipment.map((item) => (
                    <Chip key={item} variant="secondary">{item}</Chip>
                  ))
                ) : (
                  <span className="text-text-muted text-sm">Bodyweight only</span>
                )}
              </div>
            </div>
          </div>
        </GlassCard>

        {/* Active Injuries Section */}
        {(injuriesLoading || activeInjuries.length > 0) && (
          <GlassCard className="p-6 border-orange/30">
            <SectionHeader
              icon={<Icons.Bandage />}
              title="Active Injuries"
              subtitle="Currently being tracked"
            />

            {injuriesLoading ? (
              <div className="flex items-center justify-center py-8">
                <div className="w-8 h-8 border-2 border-orange border-t-transparent rounded-full animate-spin" />
              </div>
            ) : (
              <div className="space-y-4">
                {activeInjuries.map((injury) => (
                  <div key={injury.id} className="bg-orange/10 rounded-xl p-4 border border-orange/20">
                    <div className="flex justify-between items-start mb-3">
                      <div>
                        <p className="font-semibold text-text">{injury.bodyPart}</p>
                        <p className="text-sm text-text-secondary">{injury.phaseDescription}</p>
                      </div>
                      <span className={`text-xs font-semibold px-2.5 py-1 rounded-lg ${
                        injury.severity === 'mild'
                          ? 'bg-yellow-500/20 text-yellow-400'
                          : injury.severity === 'moderate'
                          ? 'bg-orange/20 text-orange'
                          : 'bg-coral/20 text-coral'
                      }`}>
                        {injury.severity}
                      </span>
                    </div>

                    <div className="mb-3">
                      <div className="flex justify-between text-xs text-text-secondary mb-1.5">
                        <span>Recovery Progress</span>
                        <span className="font-semibold text-accent">{injury.progressPercent}%</span>
                      </div>
                      <ProgressBar current={injury.progressPercent} total={100} variant="glow" />
                    </div>

                    <div className="flex justify-between text-xs text-text-muted">
                      <span>Day {injury.daysSinceInjury} of recovery</span>
                      <span>{injury.daysRemaining} days remaining</span>
                    </div>

                    {injury.rehabExercises.length > 0 && (
                      <div className="mt-3 pt-3 border-t border-orange/20">
                        <p className="text-xs font-medium text-orange mb-2">Recommended Rehab</p>
                        <div className="flex flex-wrap gap-1.5">
                          {injury.rehabExercises.slice(0, 3).map((exercise, idx) => (
                            <span key={idx} className="text-xs bg-white/5 text-text-secondary px-2 py-1 rounded-lg border border-white/10">
                              {exercise}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                ))}

                <p className="text-xs text-text-muted text-center pt-2">
                  Tell the AI coach when you're feeling better to update injury status
                </p>
              </div>
            )}
          </GlassCard>
        )}

        {/* App Info Section */}
        <GlassCard className="p-6">
          <SectionHeader icon={<Icons.Info />} title="About" />
          <div className="space-y-3">
            <div className="flex justify-between items-center py-2">
              <span className="text-text-secondary">App Name</span>
              <span className="font-medium text-text">AI Fitness Coach</span>
            </div>
            <div className="border-t border-white/10" />
            <div className="flex justify-between items-center py-2">
              <span className="text-text-secondary">Version</span>
              <span className="font-medium text-text">1.0.0</span>
            </div>
          </div>
        </GlassCard>

        {/* Logout Section */}
        <GlassCard className="p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-orange/20 rounded-xl text-orange">
              <Icons.Logout />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text">Account</h2>
              <p className="text-xs text-text-secondary">Sign out of your account</p>
            </div>
          </div>

          <p className="text-sm text-text-secondary mb-4">
            Logging out will keep your data saved. You can log back in anytime to continue your fitness journey.
          </p>

          <GlassButton
            variant="secondary"
            onClick={() => {
              log.info('User logging out');
              setUser(null);
              navigate('/login', { replace: true });
            }}
            fullWidth
            icon={<Icons.Logout />}
          >
            Log Out
          </GlassButton>
        </GlassCard>

        {/* Danger Zone */}
        <GlassCard className="p-6 border-coral/30">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-coral/20 rounded-xl text-coral">
              <Icons.Trash />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-coral">Danger Zone</h2>
              <p className="text-xs text-text-secondary">Irreversible actions</p>
            </div>
          </div>

          <p className="text-sm text-text-secondary mb-4">
            Resetting will permanently delete all your data including workouts, progress, and chat history.
          </p>

          <GlassButton
            variant="danger"
            onClick={handleResetClick}
            disabled={resetMutation.isPending}
            loading={resetMutation.isPending}
            fullWidth
            icon={<Icons.Trash />}
          >
            Reset All Data
          </GlassButton>

          {resetError && (
            <div className="mt-3 p-3 bg-coral/10 border border-coral/30 rounded-xl flex items-start gap-2">
              <Icons.Warning />
              <p className="text-coral text-sm flex-1">{resetError}</p>
            </div>
          )}
        </GlassCard>

        {/* Reset Confirmation Dialog */}
        {showResetDialog && (
          <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
            <GlassCard className="max-w-md w-full p-6" variant="elevated">
              <div className="text-center mb-5">
                <div className="w-16 h-16 bg-coral/20 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-coral" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                </div>
                <h2 className="text-xl font-bold text-text mb-2">Reset All Data?</h2>
                <p className="text-text-secondary text-sm">This will permanently delete:</p>
              </div>

              <ul className="space-y-2 mb-5">
                {[
                  'All your workouts and progress',
                  'Your preferences and goals',
                  'Chat history with AI coach'
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-3 bg-coral/10 p-3 rounded-xl border border-coral/20">
                    <div className="w-5 h-5 bg-coral/30 rounded-full flex items-center justify-center">
                      <span className="text-coral text-xs font-bold">×</span>
                    </div>
                    <span className="text-text-secondary text-sm">{item}</span>
                  </li>
                ))}
              </ul>

              <p className="text-center text-sm text-text font-medium mb-5 p-3 bg-white/5 rounded-xl border border-white/10">
                You will be taken back to onboarding.
                <br />
                <span className="text-coral">This action cannot be undone.</span>
              </p>

              {resetError && (
                <div className="mb-4 p-3 bg-coral/10 border border-coral/30 rounded-xl">
                  <p className="text-coral text-sm">{resetError}</p>
                </div>
              )}

              <div className="flex gap-3">
                <GlassButton
                  variant="secondary"
                  onClick={handleCancelReset}
                  disabled={resetMutation.isPending}
                  fullWidth
                >
                  Cancel
                </GlassButton>
                <GlassButton
                  variant="danger"
                  onClick={handleConfirmReset}
                  loading={resetMutation.isPending}
                  fullWidth
                >
                  Reset Everything
                </GlassButton>
              </div>
            </GlassCard>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
