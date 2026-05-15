// Shared fetch client for the free AI tools endpoints under /api/v1/free-tools.
//
// The existing axios client (`src/api/client.ts`) reads VITE_API_URL which
// defaults to "/api/v1". We can't reuse it directly because these endpoints
// are unauthenticated (IP-rate-limited) and we want explicit handling of the
// 429 limit-reached response shape, not generic axios errors.

// Resolve backend root by stripping a trailing /api/v1 if VITE_API_URL ends
// with it. That way the same env var works for both clients.
const RAW = import.meta.env.VITE_API_URL || '/api/v1';
const ROOT = RAW.replace(/\/api\/v1\/?$/, '') || '';
const BASE = `${ROOT}/api/v1/free-tools`;

export interface RateLimitError {
  type: 'rate-limit';
  usesRemaining: 0;
  resetsAtIso: string;
  message: string;
}

export function isRateLimitError(e: unknown): e is RateLimitError {
  return typeof e === 'object' && e !== null && (e as { type?: string }).type === 'rate-limit';
}

export async function callAiTool<T>(path: string, body: FormData | object): Promise<T> {
  const isFormData = body instanceof FormData;
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    body: isFormData ? body : JSON.stringify(body),
    headers: isFormData ? undefined : { 'Content-Type': 'application/json' },
  });

  if (res.status === 429) {
    let data: { resets_at_iso?: string; message?: string } = {};
    try {
      data = await res.json();
    } catch {
      // ignore parse failure, use defaults
    }
    const err: RateLimitError = {
      type: 'rate-limit',
      usesRemaining: 0,
      resetsAtIso: data.resets_at_iso || '',
      message: data.message || 'Daily free-tool limit reached.',
    };
    throw err;
  }

  if (!res.ok) {
    throw new Error(`AI tool error ${res.status}`);
  }
  return res.json() as Promise<T>;
}

// ---------------------------------------------------------------------------
// Email signup (shared across every free-tool page via EmailCapture component)
// ---------------------------------------------------------------------------

export interface EmailSignupPayload {
  email: string;
  tool_slug: string;
  result_summary?: Record<string, unknown>;
  source?: 'after_result' | 'during_processing' | 'manual';
}

export interface EmailSignupResponse {
  success: boolean;
  already_subscribed: boolean;
  message: string;
}

export async function submitEmailSignup(
  payload: EmailSignupPayload,
): Promise<EmailSignupResponse> {
  const res = await fetch(`${BASE}/email-signup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (res.status === 429) {
    let data: { message?: string } = {};
    try { data = await res.json(); } catch { /* ignore */ }
    throw new Error(data.message || 'Too many signups from this network. Try again in a bit.');
  }

  if (!res.ok) {
    let detail = '';
    try {
      const data = await res.json();
      detail = typeof data?.detail === 'string' ? data.detail : '';
    } catch { /* ignore */ }
    throw new Error(detail || `Signup failed (${res.status}).`);
  }

  return (await res.json()) as EmailSignupResponse;
}
