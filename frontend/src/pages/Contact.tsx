import { useState } from 'react';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { useAppStore } from '../store';
import api from '../api/client';

const CATEGORIES = [
  'Billing',
  'Technical',
  'Feature Request',
  'Bug Report',
  'Account',
  'Other',
] as const;

export default function Contact() {
  const { user, session } = useAppStore();
  const isLoggedIn = !!session?.access_token;

  const [subject, setSubject] = useState('');
  const [category, setCategory] = useState<string>(CATEGORIES[0]);
  const [message, setMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [errorMessage, setErrorMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isLoggedIn || !user) return;

    setIsSubmitting(true);
    setSubmitStatus('idle');
    setErrorMessage('');

    try {
      await api.post('/support/tickets', {
        user_id: user.id,
        subject,
        category,
        priority: 'medium',
        initial_message: message,
      });
      setSubmitStatus('success');
      setSubject('');
      setCategory(CATEGORIES[0]);
      setMessage('');
    } catch (err: any) {
      setSubmitStatus('error');
      setErrorMessage(
        err?.response?.data?.detail || 'Failed to submit support request. Please try again.'
      );
    } finally {
      setIsSubmitting(false);
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
            Contact Us
          </h1>

          <div className="space-y-12 text-[15px] text-[var(--color-text-secondary)] leading-relaxed">
            {/* Section 1: Email */}
            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Email Us
              </h2>
              <p className="mb-2">
                Reach us directly at{' '}
                <a href="mailto:support@fitwiz.us" className="text-emerald-400 hover:underline">
                  support@fitwiz.us
                </a>
              </p>
              <p className="text-[var(--color-text-muted)]">
                We typically respond within 24 hours.
              </p>
            </div>

            {/* Section 2: Community */}
            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Join the Community
              </h2>
              <p>Discord and Reddit communities coming soon.</p>
            </div>

            {/* Section 3: Support Form */}
            <div>
              <h2
                className="text-[24px] font-semibold text-[var(--color-text)] mb-4"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Submit a Support Request
              </h2>

              {!isLoggedIn ? (
                <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-6">
                  <p>
                    Please log in to submit a support request, or email us at{' '}
                    <a href="mailto:support@fitwiz.us" className="text-emerald-400 hover:underline">
                      support@fitwiz.us
                    </a>
                  </p>
                </div>
              ) : (
                <>
                  {submitStatus === 'success' && (
                    <div className="mb-6 rounded-xl border border-emerald-500/30 bg-emerald-500/10 p-4 text-emerald-400">
                      Your support request has been submitted successfully. We'll get back to you
                      soon.
                    </div>
                  )}

                  {submitStatus === 'error' && (
                    <div className="mb-6 rounded-xl border border-red-500/30 bg-red-500/10 p-4 text-red-400">
                      {errorMessage}
                    </div>
                  )}

                  <form onSubmit={handleSubmit} className="space-y-5">
                    <div>
                      <label
                        htmlFor="subject"
                        className="block text-[14px] font-medium text-[var(--color-text)] mb-1.5"
                      >
                        Subject <span className="text-red-400">*</span>
                      </label>
                      <input
                        id="subject"
                        type="text"
                        required
                        value={subject}
                        onChange={(e) => setSubject(e.target.value)}
                        placeholder="Brief description of your issue"
                        className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-4 py-2.5 text-[15px] text-[var(--color-text)] placeholder-[var(--color-text-muted)] outline-none focus:border-emerald-400 focus:ring-1 focus:ring-emerald-400 transition-colors"
                      />
                    </div>

                    <div>
                      <label
                        htmlFor="category"
                        className="block text-[14px] font-medium text-[var(--color-text)] mb-1.5"
                      >
                        Category
                      </label>
                      <select
                        id="category"
                        value={category}
                        onChange={(e) => setCategory(e.target.value)}
                        className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-4 py-2.5 text-[15px] text-[var(--color-text)] outline-none focus:border-emerald-400 focus:ring-1 focus:ring-emerald-400 transition-colors"
                      >
                        {CATEGORIES.map((cat) => (
                          <option key={cat} value={cat}>
                            {cat}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label
                        htmlFor="message"
                        className="block text-[14px] font-medium text-[var(--color-text)] mb-1.5"
                      >
                        Message <span className="text-red-400">*</span>
                      </label>
                      <textarea
                        id="message"
                        required
                        rows={6}
                        value={message}
                        onChange={(e) => setMessage(e.target.value)}
                        placeholder="Describe your issue or question in detail"
                        className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-4 py-2.5 text-[15px] text-[var(--color-text)] placeholder-[var(--color-text-muted)] outline-none focus:border-emerald-400 focus:ring-1 focus:ring-emerald-400 transition-colors resize-y"
                      />
                    </div>

                    <button
                      type="submit"
                      disabled={isSubmitting}
                      className="inline-flex items-center justify-center rounded-lg bg-emerald-500 px-6 py-2.5 text-[15px] font-medium text-white hover:bg-emerald-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                      {isSubmitting ? 'Submitting...' : 'Submit Request'}
                    </button>
                  </form>
                </>
              )}
            </div>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
