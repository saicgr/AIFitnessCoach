// MCP OAuth consent page logic.
//
// Lives as an external, same-origin file (NOT inline in authorize.html)
// because the app-wide CSP is `default-src 'self'` with no 'unsafe-inline' —
// an inline <script> block is silently blocked by every modern browser under
// that policy, which is why this page used to hang forever on "Loading
// authorization details...": the script that would resolve that state never
// ran at all. Server-injected config (consent token, backend URLs, Supabase
// creds) comes in via data-* attributes on <body> instead of templated JS
// literals, since this file itself is static and never passes through Jinja.

const body = document.body;
const CONSENT_TOKEN     = body.dataset.consentToken || "";
const PEEK_URL          = body.dataset.peekUrl || "";
const COMPLETE_URL      = body.dataset.completeUrl || "";
const UPGRADE_PATH      = body.dataset.upgradePath || "";
const SUPABASE_URL      = body.dataset.supabaseUrl || "";
const SUPABASE_ANON_KEY = body.dataset.supabaseAnonKey || "";
const APP_NAME          = body.dataset.appName || "Zealova";

// Per-scope plain-English impact notes. Mirrors backend MCPConfig.SCOPES.
const SCOPE_IMPACT = {
  "read:profile":   "The AI will see your goals, body metrics, and preferences.",
  "read:workouts":  "The AI will see your workout plan and completed sessions.",
  "read:nutrition": "The AI will see meals, water, and macros you've logged.",
  "read:scores":    "The AI will see your readiness and strength scores.",
  "write:logs":     "The AI can log meals, water, sets, and body weight on your behalf.",
  "write:workouts": "The AI can generate or modify your workout plans.",
  "chat:coach":     `The AI can talk to your ${APP_NAME} coach and run agent tools.`,
  "export:data":    "The AI can export your data and generate reports (PDF / CSV).",
};
const WRITE_SCOPES = new Set([
  "write:logs", "write:workouts", "chat:coach", "export:data",
]);

// ─── Supabase client (only if env is configured) ───────────────────────
// When SUPABASE_ANON_KEY is blank, we silently fall back to the manual
// paste-token UI so the OAuth flow keeps working during initial rollout.
const HAS_SUPABASE_AUTH =
  Boolean(SUPABASE_URL) && Boolean(SUPABASE_ANON_KEY) &&
  typeof window.supabase !== "undefined";
const sb = HAS_SUPABASE_AUTH
  ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        persistSession: false, // tab is throwaway; don't pollute other tabs
        autoRefreshToken: false,
        // The OAuth provider redirects back to THIS exact URL. We keep
        // the consent= query param so the page can resume on return.
        detectSessionInUrl: true,
      },
    })
  : null;

// ─── DOM shortcuts ─────────────────────────────────────────────────────
const $ = (id) => document.getElementById(id);
const stateLoading  = $("stateLoading");
const stateError    = $("stateError");
const stateForm     = $("stateForm");
const errorMsg      = $("errorMsg");
const clientName    = $("clientName");
const clientNameAck = $("clientNameAck");
const scopeList     = $("scopeList");
const ackCheckbox   = $("ackCheckbox");
const authorizeBtn  = $("authorizeBtn");
const authBtnLabel  = authorizeBtn.querySelector(".btn-label");
const authBtnSpin   = authorizeBtn.querySelector(".btn-spinner");
const cancelBtn     = $("cancelBtn");
const submitError   = $("submitError");
const oauthRow      = $("oauthRow");
const oauthDivider  = $("oauthDivider");
const signinForm    = $("signinForm");
const signinBtn     = $("signinBtn");
const signinBtnLbl  = signinBtn.querySelector(".btn-label");
const signinBtnSpin = signinBtn.querySelector(".btn-spinner");
const emailInput    = $("emailInput");
const passwordInput = $("passwordInput");
const signedBanner  = $("signedInBanner");
const signedEmail   = $("signedInEmail");
const signOutBtn    = $("signOutBtn");
const manualFallback = $("manualTokenFallback");
const manualToken    = $("manualToken");

// The token we'll pass to /complete. Set after sign-in succeeds OR after
// the user pastes one into the manual fallback textarea.
let resolvedToken = "";

// ─── State transitions ────────────────────────────────────────────────
function showError(msg) {
  stateLoading.hidden = true;
  stateForm.hidden = true;
  stateError.hidden = false;
  if (msg) errorMsg.textContent = msg;
}
function showForm() {
  stateLoading.hidden = true;
  stateError.hidden = true;
  stateForm.hidden = false;

  if (HAS_SUPABASE_AUTH) {
    // Show OAuth row + sign-in form.
    oauthRow.hidden = false;
    oauthDivider.hidden = false;
    manualFallback.hidden = true;

    // If a Supabase OAuth callback dropped us back here with an active
    // session in the URL hash, pick it up and skip the password prompt.
    rehydrateSessionFromUrlIfPresent();
  } else {
    // Anon key not configured — fall back to manual paste UI so the
    // OAuth handshake still works.
    oauthRow.hidden = true;
    oauthDivider.hidden = true;
    signinForm.hidden = true;
    manualFallback.hidden = false;
  }
}

// ─── Peek: fetch client + scopes for the consent token ────────────────
async function loadConsentDetails() {
  if (!CONSENT_TOKEN) {
    showError("Missing consent token. Open this page from your AI client's connection flow.");
    return;
  }
  try {
    const resp = await fetch(
      `${PEEK_URL}?consent=${encodeURIComponent(CONSENT_TOKEN)}`,
      { method: "GET", headers: { "Accept": "application/json" } }
    );
    if (!resp.ok) {
      const body = await resp.json().catch(() => ({}));
      const desc = (body && body.detail && body.detail.error_description) || "Consent link is invalid or expired.";
      showError(desc);
      return;
    }
    const data = await resp.json();
    renderForm(data);
  } catch (e) {
    console.error(e);
    showError(`Could not reach ${APP_NAME} servers. Check your connection and try again.`);
  }
}

// ─── Render the consent form with scope checkboxes ────────────────────
function renderForm(data) {
  const name = data.client_name || "Unknown app";
  clientName.textContent = name;
  clientNameAck.textContent = name;

  scopeList.innerHTML = "";
  const scopes = data.requested_scopes || [];
  if (!scopes.length) {
    showError("This request doesn't ask for any scopes — nothing to approve.");
    return;
  }
  scopes.forEach((s, idx) => {
    const id = `scope_${idx}`;
    const isWrite = WRITE_SCOPES.has(s.scope);
    const impact = SCOPE_IMPACT[s.scope] || "";
    const li = document.createElement("li");
    li.className = "scope-item" + (isWrite ? " scope-item-write" : "");
    li.innerHTML = `
      <label for="${id}" class="scope-label">
        <input type="checkbox" id="${id}" class="scope-cb" data-scope="${s.scope}" checked />
        <div class="scope-text">
          <div class="scope-head">
            <code class="scope-key">${escapeHtml(s.scope)}</code>
            ${isWrite ? '<span class="badge badge-write">write</span>' : '<span class="badge badge-read">read</span>'}
          </div>
          <div class="scope-desc">${escapeHtml(s.description || "")}</div>
          ${impact ? `<div class="scope-impact">${escapeHtml(impact)}</div>` : ""}
        </div>
      </label>
    `;
    scopeList.appendChild(li);
  });

  scopeList.querySelectorAll(".scope-cb").forEach((cb) => {
    cb.addEventListener("change", updateAuthorizeEnabled);
  });
  ackCheckbox.addEventListener("change", updateAuthorizeEnabled);
  manualToken.addEventListener("input", () => {
    resolvedToken = manualToken.value.trim();
    updateAuthorizeEnabled();
  });

  showForm();
  updateAuthorizeEnabled();
}

function updateAuthorizeEnabled() {
  const anyScope = Array.from(scopeList.querySelectorAll(".scope-cb")).some((cb) => cb.checked);
  // JWTs are 200+ chars; 20 is a cheap sanity check.
  const haveToken = resolvedToken && resolvedToken.length > 20;
  const acked = ackCheckbox.checked;
  authorizeBtn.disabled = !(anyScope && haveToken && acked);
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

// ─── Email/password sign-in ───────────────────────────────────────────
signinForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  if (!sb) return;

  const email = emailInput.value.trim();
  const password = passwordInput.value;
  if (!email || !password) return;

  signinBtn.disabled = true;
  signinBtnLbl.textContent = "Signing in…";
  signinBtnSpin.hidden = false;
  submitError.hidden = true;

  try {
    const { data, error } = await sb.auth.signInWithPassword({ email, password });
    if (error) throw error;
    if (!data || !data.session) throw new Error("Sign-in returned no session.");
    markSignedIn(data.session);
  } catch (err) {
    console.error(err);
    submitError.textContent = err && err.message
      ? `Sign-in failed: ${err.message}`
      : "Sign-in failed. Double-check your email and password.";
    submitError.hidden = false;
  } finally {
    signinBtn.disabled = false;
    signinBtnLbl.textContent = "Sign in";
    signinBtnSpin.hidden = true;
  }
});

// ─── OAuth (Google / Apple) ───────────────────────────────────────────
document.querySelectorAll(".btn-oauth").forEach((btn) => {
  btn.addEventListener("click", async () => {
    if (!sb) return;
    const provider = btn.dataset.provider;
    submitError.hidden = true;
    try {
      // Round-trip: Supabase redirects to the provider, the provider
      // redirects back to Supabase, Supabase redirects HERE with the
      // session in the URL hash. We re-render the page on return and
      // pick up the session via detectSessionInUrl.
      const back = window.location.href;
      const { error } = await sb.auth.signInWithOAuth({
        provider,
        options: { redirectTo: back },
      });
      if (error) throw error;
    } catch (err) {
      console.error(err);
      submitError.textContent =
        `Could not start ${provider} sign-in. ${err && err.message ? err.message : ""}`;
      submitError.hidden = false;
    }
  });
});

async function rehydrateSessionFromUrlIfPresent() {
  if (!sb) return;
  try {
    const { data } = await sb.auth.getSession();
    if (data && data.session) {
      markSignedIn(data.session);
    }
  } catch (e) {
    console.warn("Could not rehydrate Supabase session:", e);
  }
}

function markSignedIn(session) {
  resolvedToken = session.access_token || "";
  const email = (session.user && session.user.email) || "your account";
  signedEmail.textContent = email;
  signinForm.hidden = true;
  oauthRow.hidden = true;
  oauthDivider.hidden = true;
  signedBanner.hidden = false;
  submitError.hidden = true;
  updateAuthorizeEnabled();
}

signOutBtn.addEventListener("click", async () => {
  if (sb) {
    try { await sb.auth.signOut(); } catch (_) { /* ignore */ }
  }
  resolvedToken = "";
  signedBanner.hidden = true;
  signinForm.hidden = false;
  oauthRow.hidden = false;
  oauthDivider.hidden = false;
  emailInput.value = "";
  passwordInput.value = "";
  updateAuthorizeEnabled();
});

// ─── Submit: POST to /complete, handle redirect / 402 upgrade ─────────
async function submitAuthorization() {
  submitError.hidden = true;
  submitError.textContent = "";
  authorizeBtn.disabled = true;
  authBtnLabel.textContent = "Authorizing…";
  authBtnSpin.hidden = false;

  const approved_scopes = Array.from(scopeList.querySelectorAll(".scope-cb:checked"))
    .map((cb) => cb.dataset.scope);

  try {
    const resp = await fetch(COMPLETE_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({
        consent: CONSENT_TOKEN,
        supabase_access_token: resolvedToken,
        approved_scopes,
      }),
    });

    if (resp.status === 402) {
      window.location.href = UPGRADE_PATH;
      return;
    }

    if (!resp.ok) {
      const body2 = await resp.json().catch(() => ({}));
      const desc =
        (body2 && body2.detail && body2.detail.error_description) ||
        (body2 && body2.detail && body2.detail.error) ||
        `Authorization failed (HTTP ${resp.status}).`;
      submitError.textContent = desc;
      submitError.hidden = false;
      authBtnLabel.textContent = "Authorize";
      authBtnSpin.hidden = true;
      updateAuthorizeEnabled();
      return;
    }

    const data = await resp.json();
    if (data && data.redirect_to) {
      window.location.href = data.redirect_to;
    } else {
      window.location.href = "/mcp/consent/success";
    }
  } catch (e) {
    console.error(e);
    submitError.textContent = "Network error — please try again.";
    submitError.hidden = false;
    authBtnLabel.textContent = "Authorize";
    authBtnSpin.hidden = true;
    updateAuthorizeEnabled();
  }
}

cancelBtn.addEventListener("click", () => {
  // Best-effort tab close (only works for windows opened via JS).
  window.close();
  setTimeout(() => {
    submitError.textContent = "Authorization cancelled. You can close this tab.";
    submitError.hidden = false;
  }, 150);
});
authorizeBtn.addEventListener("click", submitAuthorization);

// Kick off.
loadConsentDetails();
