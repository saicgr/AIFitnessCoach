/**
 * AdminLogin - Admin dashboard login page
 *
 * Features:
 * - Email/password authentication
 * - Glassmorphism styling consistent with main app
 * - Error handling with user-friendly messages
 * - Redirect to dashboard on success
 */
import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAdminStore } from '../../store/adminStore';
import { adminLogin } from '../../api/client';
import GlassInput from '../../components/ui/GlassInput';
import GlassButton from '../../components/ui/GlassButton';

export default function AdminLogin() {
  const navigate = useNavigate();
  const { setSession } = useAdminStore();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await adminLogin({ email, password });
      setSession(response.session);
      navigate('/admin/dashboard');
    } catch (err: unknown) {
      console.error('Admin login failed:', err);
      if (err && typeof err === 'object' && 'response' in err) {
        const axiosError = err as { response?: { status?: number; data?: { message?: string } } };
        if (axiosError.response?.status === 401) {
          setError('Invalid email or password');
        } else if (axiosError.response?.status === 403) {
          setError('Your account does not have admin access');
        } else {
          setError(axiosError.response?.data?.message || 'Login failed. Please try again.');
        }
      } else {
        setError('Unable to connect to server. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      {/* Background decorations */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-primary/5 rounded-full blur-[100px]" />
        <div className="absolute bottom-1/4 left-0 w-[500px] h-[500px] bg-secondary/5 rounded-full blur-[100px]" />
        <div className="absolute top-1/2 right-1/4 w-[400px] h-[400px] bg-accent/3 rounded-full blur-[80px]" />
      </div>

      {/* Login Card */}
      <div className="relative z-10 w-full max-w-md">
        <div className="glass-card p-8 rounded-3xl">
          {/* Header */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-primary to-secondary mb-4">
              <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
            </div>
            <h1 className="text-2xl font-bold text-text mb-2">Admin Dashboard</h1>
            <p className="text-text-secondary">Sign in to access the admin panel</p>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Error Message */}
            {error && (
              <div className="p-4 rounded-xl bg-coral/10 border border-coral/30 flex items-center gap-3">
                <svg className="w-5 h-5 text-coral flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p className="text-sm text-coral">{error}</p>
              </div>
            )}

            {/* Email Input */}
            <GlassInput
              type="email"
              label="Email Address"
              placeholder="admin@fitwiz.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              icon={
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
              }
            />

            {/* Password Input */}
            <GlassInput
              type="password"
              label="Password"
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              icon={
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              }
            />

            {/* Submit Button */}
            <GlassButton
              type="submit"
              fullWidth
              loading={loading}
              disabled={!email || !password}
            >
              Sign In
            </GlassButton>
          </form>

          {/* Footer */}
          <div className="mt-8 text-center">
            <p className="text-xs text-text-muted">
              Having trouble logging in?{' '}
              <a href="mailto:support@fitwiz.com" className="text-primary hover:underline">
                Contact Support
              </a>
            </p>
          </div>
        </div>

        {/* Security Notice */}
        <div className="mt-6 text-center">
          <p className="text-xs text-text-muted flex items-center justify-center gap-2">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
            Secure connection protected by SSL
          </p>
        </div>
      </div>
    </div>
  );
}
