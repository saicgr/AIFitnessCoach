import { useState } from 'react';
import { Link } from 'react-router-dom';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { useAppStore } from '../store';
import api from '../api/client';
import { BRANDING } from '../lib/branding';

export default function DeleteAccount() {
  const { user, session } = useAppStore();
  const isLoggedIn = !!session?.access_token;

  const [showConfirm, setShowConfirm] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteStatus, setDeleteStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [errorMessage, setErrorMessage] = useState('');

  const handleDelete = async () => {
    if (!isLoggedIn || !user) return;

    setIsDeleting(true);
    setDeleteStatus('idle');
    setErrorMessage('');

    try {
      await api.delete(`/users/${user.id}`);
      setDeleteStatus('success');
      setShowConfirm(false);
    } catch (err: any) {
      setDeleteStatus('error');
      setErrorMessage(
        err?.response?.data?.detail ||
          'Failed to delete account. Please try again or contact support.'
      );
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          <h1
            className="text-[36px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-8"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Delete Your Account
          </h1>

          <div className="space-y-8 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            {/* Warning */}
            <div className="rounded-xl border border-red-500/30 bg-red-500/10 p-6">
              <p className="text-red-400 font-semibold text-[17px] mb-2">Warning</p>
              <p className="text-red-300">
                Deleting your account is permanent and cannot be undone. All of your data will be
                permanently removed from our servers.
              </p>
            </div>

            {/* Success state */}
            {deleteStatus === 'success' && (
              <div className="rounded-xl border border-emerald-500/30 bg-emerald-500/10 p-6 text-emerald-400">
                Your account deletion request has been submitted. Your data will be removed within
                30 days.
              </div>
            )}

            {/* Error state */}
            {deleteStatus === 'error' && (
              <div className="rounded-xl border border-red-500/30 bg-red-500/10 p-4 text-red-400">
                {errorMessage}
              </div>
            )}

            {/* What gets deleted */}
            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                What Gets Deleted
              </h2>
              <p className="mb-4">
                When you delete your account, the following data will be permanently removed:
              </p>
              <ul className="list-disc pl-6 space-y-1">
                <li>All workout history and logs</li>
                <li>All nutrition data and meal logs</li>
                <li>AI coach conversation history</li>
                <li>Personal profile and settings</li>
                <li>Subscription (will be cancelled)</li>
              </ul>
            </div>

            {/* How to delete */}
            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                How to Delete Your Account
              </h2>
              <ol className="list-decimal pl-6 space-y-2">
                <li>Open the {BRANDING.appName} app</li>
                <li>Go to Settings &gt; Privacy &amp; Data</li>
                <li>Tap "Delete Account"</li>
                <li>Confirm deletion</li>
              </ol>
            </div>

            {/* Alternative */}
            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Alternative
              </h2>
              <p>
                You can also email{' '}
                <a href={`mailto:support@${BRANDING.marketingDomain}`} className="text-emerald-400 hover:underline">
                  support@{BRANDING.marketingDomain}
                </a>{' '}
                to request account deletion.
              </p>
            </div>

            {/* Privacy policy link */}
            <div>
              <p>
                For more information about how we handle your data, please read our{' '}
                <Link to="/privacy" className="text-emerald-400 hover:underline">
                  Privacy Policy
                </Link>
                .
              </p>
            </div>

            {/* Delete button for logged-in users */}
            {isLoggedIn && deleteStatus !== 'success' && (
              <div className="pt-4 border-t border-[var(--color-border)]">
                {!showConfirm ? (
                  <button
                    onClick={() => setShowConfirm(true)}
                    className="inline-flex items-center justify-center rounded-lg bg-red-500 px-6 py-2.5 text-[15px] font-medium text-white hover:bg-red-600 transition-colors"
                  >
                    Delete My Account
                  </button>
                ) : (
                  <div className="rounded-xl border border-red-500/30 bg-red-500/10 p-6">
                    <p className="text-red-400 font-semibold mb-4">
                      Are you sure? This action cannot be undone.
                    </p>
                    <div className="flex gap-3">
                      <button
                        onClick={handleDelete}
                        disabled={isDeleting}
                        className="inline-flex items-center justify-center rounded-lg bg-red-500 px-6 py-2.5 text-[15px] font-medium text-white hover:bg-red-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                      >
                        {isDeleting ? 'Deleting...' : 'Yes, Delete My Account'}
                      </button>
                      <button
                        onClick={() => setShowConfirm(false)}
                        disabled={isDeleting}
                        className="inline-flex items-center justify-center rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-6 py-2.5 text-[15px] font-medium text-[var(--color-text)] hover:bg-[var(--color-border)] disabled:opacity-50 transition-colors"
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
