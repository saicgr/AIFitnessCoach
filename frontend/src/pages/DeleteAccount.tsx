import { useEffect, useState } from 'react';
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

  useEffect(() => {
    document.title = 'Delete Your Account | Zealova';
    const setMeta = (key: string, value: string, isProperty = false) => {
      const attr = isProperty ? 'property' : 'name';
      let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${key}"]`);
      if (!el) {
        el = document.createElement('meta');
        el.setAttribute(attr, key);
        document.head.appendChild(el);
      }
      el.content = value;
    };
    setMeta(
      'description',
      'Request permanent deletion of your Zealova account and all associated data.'
    );
  }, []);

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
    <div className="min-h-screen bg-[#050505] text-zinc-100">
      <MarketingNav />

      <section className="pt-28 pb-20 px-6">
        <div className="max-w-[800px] mx-auto">
          <p className="condensed-kicker text-volt-500 text-[13px] mb-3">Account</p>
          <h1 className="display-heading text-4xl sm:text-5xl text-white mb-8">
            Delete Your Account
          </h1>

          <div className="space-y-8 text-[15px] text-zinc-300 leading-relaxed">
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
              <div className="rounded-xl border border-volt-500/30 bg-volt-500/10 p-6 text-volt-300">
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
              <h2 className="text-[24px] font-semibold text-white mb-4">
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
              <h2 className="text-[24px] font-semibold text-white mb-4">
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
              <h2 className="text-[24px] font-semibold text-white mb-4">
                Alternative
              </h2>
              <p>
                You can also email{' '}
                <a href={`mailto:support@${BRANDING.marketingDomain}`} className="text-volt-400 hover:text-volt-300 hover:underline">
                  support@{BRANDING.marketingDomain}
                </a>{' '}
                to request account deletion.
              </p>
            </div>

            {/* Privacy policy link */}
            <div>
              <p>
                For more information about how we handle your data, please read our{' '}
                <Link to="/privacy" className="text-volt-400 hover:text-volt-300 hover:underline">
                  Privacy Policy
                </Link>
                .
              </p>
            </div>

            {/* Delete button for logged-in users */}
            {isLoggedIn && deleteStatus !== 'success' && (
              <div className="pt-4 border-t border-white/10">
                {!showConfirm ? (
                  <button
                    onClick={() => setShowConfirm(true)}
                    className="inline-flex items-center justify-center rounded-full bg-red-600 px-6 py-3 text-[15px] font-semibold text-white hover:bg-red-500 transition-colors"
                  >
                    Delete My Account
                  </button>
                ) : (
                  <div className="rounded-xl border border-red-500/30 bg-red-500/10 p-6">
                    <p className="text-red-400 font-semibold mb-4">
                      Are you sure? This action cannot be undone.
                    </p>
                    <div className="flex flex-col sm:flex-row gap-3">
                      <button
                        onClick={handleDelete}
                        disabled={isDeleting}
                        className="inline-flex items-center justify-center rounded-full bg-red-600 px-6 py-3 text-[15px] font-semibold text-white hover:bg-red-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                      >
                        {isDeleting ? 'Deleting...' : 'Yes, Delete My Account'}
                      </button>
                      <button
                        onClick={() => setShowConfirm(false)}
                        disabled={isDeleting}
                        className="inline-flex items-center justify-center rounded-full border border-white/10 bg-[#0D0D0D] px-6 py-3 text-[15px] font-medium text-zinc-200 hover:bg-white/5 disabled:opacity-50 transition-colors"
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
