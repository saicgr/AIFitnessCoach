import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { useAppStore, clearAppStorage } from '../store';
import { resetUser } from '../api/client';
import { createLogger } from '../utils/logger';

const log = createLogger('settings');

export default function Settings() {
  const navigate = useNavigate();
  const { user } = useAppStore();
  const [showResetDialog, setShowResetDialog] = useState(false);
  const [resetError, setResetError] = useState<string | null>(null);

  const resetMutation = useMutation({
    mutationFn: async () => {
      if (!user) throw new Error('No user found');

      log.info('Starting full reset for user', { userId: user.id });

      // Call backend to delete all user data
      await resetUser(user.id);

      log.info('Backend reset successful');
    },
    onSuccess: () => {
      log.info('Reset successful, clearing local storage');

      // Clear all local storage and state
      clearAppStorage();

      // Navigate to onboarding
      navigate('/onboarding', { replace: true });
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
    navigate('/onboarding');
    return null;
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="bg-primary text-white p-4">
        <div className="max-w-2xl mx-auto flex items-center justify-between">
          <button
            onClick={() => navigate(-1)}
            className="text-white/70 hover:text-white"
          >
            ← Back
          </button>
          <h1 className="text-xl font-bold">Settings</h1>
          <div className="w-16"></div> {/* Spacer for centering */}
        </div>
      </header>

      <main className="max-w-2xl mx-auto p-4 space-y-6">
        {/* User Info Section */}
        <section className="bg-white rounded-xl p-6 border border-gray-100">
          <h2 className="text-lg font-bold text-gray-900 mb-4">Profile</h2>
          <div className="space-y-3">
            <div>
              <p className="text-sm text-gray-500">Fitness Level</p>
              <p className="text-base font-medium text-gray-900 capitalize">{user.fitness_level}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Goals</p>
              <div className="flex flex-wrap gap-2 mt-1">
                {user.goals.map((goal) => (
                  <span
                    key={goal}
                    className="px-3 py-1 bg-primary/10 text-primary rounded-full text-sm font-medium"
                  >
                    {goal}
                  </span>
                ))}
              </div>
            </div>
            <div>
              <p className="text-sm text-gray-500">Equipment</p>
              <div className="flex flex-wrap gap-2 mt-1">
                {user.equipment.length > 0 ? (
                  user.equipment.map((item) => (
                    <span
                      key={item}
                      className="px-3 py-1 bg-secondary/10 text-secondary rounded-full text-sm font-medium"
                    >
                      {item}
                    </span>
                  ))
                ) : (
                  <span className="text-gray-400 text-sm">No equipment</span>
                )}
              </div>
            </div>
          </div>
        </section>

        {/* Danger Zone Section */}
        <section className="bg-white rounded-xl p-6 border border-red-200">
          <h2 className="text-lg font-bold text-red-600 mb-2">Danger Zone</h2>
          <p className="text-sm text-gray-600 mb-4">
            This action is irreversible. Please proceed with caution.
          </p>
          <button
            onClick={handleResetClick}
            disabled={resetMutation.isPending}
            className="w-full px-4 py-3 bg-red-600 text-white rounded-xl font-semibold hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {resetMutation.isPending ? 'Resetting...' : 'Reset All Data'}
          </button>
          {resetError && (
            <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-red-700 text-sm">{resetError}</p>
            </div>
          )}
        </section>

        {/* App Info Section */}
        <section className="bg-white rounded-xl p-6 border border-gray-100">
          <h2 className="text-lg font-bold text-gray-900 mb-4">About</h2>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-500">App Name</span>
              <span className="text-gray-900 font-medium">AI Fitness Coach</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Version</span>
              <span className="text-gray-900 font-medium">1.0.0</span>
            </div>
          </div>
        </section>
      </main>

      {/* Reset Confirmation Dialog */}
      {showResetDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-xl">
            <div className="text-center mb-4">
              <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <h2 className="text-xl font-bold text-red-600 mb-3">Reset All Data?</h2>
              <p className="text-gray-600 text-sm leading-relaxed">
                Are you sure you want to reset all data? This will delete:
              </p>
              <ul className="text-left text-gray-600 text-sm mt-3 space-y-2">
                <li className="flex items-start gap-2">
                  <span className="text-red-500 mt-0.5">•</span>
                  <span>All your workouts and progress</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-red-500 mt-0.5">•</span>
                  <span>Your preferences and goals</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-red-500 mt-0.5">•</span>
                  <span>Chat history with AI coach</span>
                </li>
              </ul>
              <p className="text-gray-900 font-medium text-sm mt-4">
                You will be taken back to onboarding. This action cannot be undone.
              </p>
            </div>

            {resetError && (
              <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-red-700 text-sm">{resetError}</p>
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={handleCancelReset}
                disabled={resetMutation.isPending}
                className="flex-1 px-4 py-3 border border-gray-300 text-gray-700 rounded-xl font-semibold hover:bg-gray-50 transition-colors disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmReset}
                disabled={resetMutation.isPending}
                className="flex-1 px-4 py-3 bg-red-600 text-white rounded-xl font-semibold hover:bg-red-700 transition-colors disabled:opacity-50"
              >
                {resetMutation.isPending ? 'Resetting...' : 'Reset Everything'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
