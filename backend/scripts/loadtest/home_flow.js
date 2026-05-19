/*
 * Zealova — Home hot-path load test (Phase C)
 * ============================================
 *
 * Simulates a "Home screen open": one authenticated GET /api/v1/home/bootstrap
 * (which itself fans out to 5 parallel DB queries server-side) plus one
 * realistic follow-up call the Home screen makes (GET /workouts/today, used by
 * the hero workout carousel when the user taps through).
 *
 * The goal of this harness is to find the ~10k-concurrent SATURATION POINT of
 * the Home path so Phase D can tune workers / DB pool / Redis accordingly.
 *
 * ─── SAFETY ─────────────────────────────────────────────────────────────────
 *   * This script is STAGING-ONLY. It refuses to run against a production-
 *     looking host unless ALLOW_PROD=1 is explicitly set (you should never
 *     need to do that — see README.md).
 *   * BASE_URL is REQUIRED and has no default. There is no way to accidentally
 *     point this at prod by forgetting a flag.
 *   * No secrets are embedded. JWTs are read from tokens.txt (one per line) or
 *     the TOKENS env var. tokens.txt is gitignored — see README.md.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *   k6 run \
 *     -e BASE_URL=https://fitwiz-backend-staging.onrender.com \
 *     backend/scripts/loadtest/home_flow.js
 *
 * See README.md in this directory for the full runbook.
 */

import http from 'k6/http';
import { check, sleep, fail } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';
import { SharedArray } from 'k6/data';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.3/index.js';

// =============================================================================
// Configuration — all via environment variables, nothing hardcoded.
// =============================================================================

const BASE_URL   = (__ENV.BASE_URL || '').replace(/\/+$/, ''); // strip trailing /
const TOKENS_FILE = __ENV.TOKENS_FILE || 'tokens.txt';
const ALLOW_PROD  = __ENV.ALLOW_PROD === '1';
// Optional: run a shorter smoke profile (SMOKE=1) instead of the full ramp.
const SMOKE       = __ENV.SMOKE === '1';
// Think-time between the two requests in a Home open, in seconds.
const THINK_MIN   = Number(__ENV.THINK_MIN || 0.5);
const THINK_MAX   = Number(__ENV.THINK_MAX || 2.0);

// --- Hard safety guards: fail fast before generating any traffic. -----------
if (!BASE_URL) {
  fail(
    'BASE_URL is required. Example:\n' +
    '  k6 run -e BASE_URL=https://fitwiz-backend-staging.onrender.com home_flow.js'
  );
}
// Heuristic prod-host blocklist. Extend if the prod host changes.
const PROD_HOST_MARKERS = ['fitwiz-backend.onrender.com', 'api.zealova.com', 'zealova.com'];
const looksLikeProd = PROD_HOST_MARKERS.some((m) => BASE_URL.includes(m));
if (looksLikeProd && !ALLOW_PROD) {
  fail(
    `Refusing to run: BASE_URL "${BASE_URL}" looks like PRODUCTION.\n` +
    'This harness is staging-only. Point it at the staging service.\n' +
    '(If you genuinely must target this host, set ALLOW_PROD=1 — do not.)'
  );
}

// =============================================================================
// Token pool — loaded once, shared across all VUs (SharedArray = no per-VU copy).
// =============================================================================

const TOKENS = new SharedArray('jwt-pool', function () {
  // 1) Prefer the TOKENS env var (newline-separated) for CI use.
  let raw = __ENV.TOKENS || '';
  // 2) Otherwise read tokens.txt from this directory.
  if (!raw) {
    try {
      raw = open(TOKENS_FILE);
    } catch (e) {
      fail(
        `Could not read token pool. Provide JWTs one-per-line in "${TOKENS_FILE}" ` +
        'or via the TOKENS env var.\n' +
        'Mint a disposable batch with: python mint_test_tokens.py --count 200\n' +
        `Underlying error: ${e}`
      );
    }
  }
  const tokens = raw
    .split('\n')
    .map((l) => l.trim())
    // Skip blank lines and comments so tokens.txt can be annotated.
    .filter((l) => l && !l.startsWith('#'));
  if (tokens.length === 0) {
    fail(`Token pool is empty. Add JWTs to "${TOKENS_FILE}" (one per line).`);
  }
  return tokens;
});

// Each line in tokens.txt may be "<jwt>" or "<jwt>\t<user_id>". The bootstrap
// endpoint requires a ?user_id= query param that must match the JWT's user
// (IDOR check is on other endpoints but bootstrap still needs the id). If the
// user_id is not supplied alongside the token we decode it from the JWT `sub`.
function parseTokenEntry(entry) {
  const parts = entry.split(/[\t,]/).map((s) => s.trim());
  const token = parts[0];
  let userId = parts[1] || null;
  if (!userId) {
    userId = decodeSub(token);
  }
  return { token, userId };
}

// Minimal, dependency-free JWT payload decode (NOT verification — we only need
// the `sub` claim to build the user_id query param).
function decodeSub(jwt) {
  try {
    const payload = jwt.split('.')[1];
    // base64url -> base64
    const b64 = payload.replace(/-/g, '+').replace(/_/g, '/');
    const json = decodeBase64(b64);
    return JSON.parse(json).sub || null;
  } catch (e) {
    return null;
  }
}

function decodeBase64(b64) {
  // k6 has no atob; do a small pure-JS base64 decoder.
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  let str = '';
  let buffer = 0;
  let bits = 0;
  for (let i = 0; i < b64.length; i++) {
    const c = b64.charAt(i);
    if (c === '=') break;
    const idx = chars.indexOf(c);
    if (idx === -1) continue;
    buffer = (buffer << 6) | idx;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      str += String.fromCharCode((buffer >> bits) & 0xff);
    }
  }
  return str;
}

// =============================================================================
// Custom metrics — tagged so bootstrap is isolated from the follow-up call.
// =============================================================================

const bootstrapLatency = new Trend('home_bootstrap_latency', true);
const followupLatency  = new Trend('home_followup_latency', true);
const bootstrapErrors  = new Rate('home_bootstrap_error_rate');
const cacheHits        = new Counter('home_bootstrap_cache_hits');
const cacheMisses      = new Counter('home_bootstrap_cache_misses');

// =============================================================================
// Load profile — staged ramp 100 -> 1k -> 5k -> 10k with holds, then ramp-down.
// =============================================================================

const fullRamp = [
  // Warm-up so Render/Redis caches are primed before measurement.
  { duration: '1m',  target: 100 },
  { duration: '2m',  target: 100 },   // hold @ 100
  { duration: '2m',  target: 1000 },
  { duration: '3m',  target: 1000 },  // hold @ 1k
  { duration: '3m',  target: 5000 },
  { duration: '4m',  target: 5000 },  // hold @ 5k
  { duration: '4m',  target: 10000 },
  { duration: '5m',  target: 10000 }, // hold @ 10k — the saturation target
  { duration: '3m',  target: 0 },     // graceful ramp-down
];

const smokeRamp = [
  { duration: '30s', target: 20 },
  { duration: '1m',  target: 20 },
  { duration: '20s', target: 0 },
];

export const options = {
  scenarios: {
    home_open: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: SMOKE ? smokeRamp : fullRamp,
      gracefulRampDown: '30s',
      // 10k VUs is a lot of OS threads/goroutines — k6 itself needs headroom.
      // See README.md "Generating from one box vs distributed".
    },
  },
  thresholds: {
    // --- Bootstrap (the hot path under test) ---------------------------------
    // p95 budget: the endpoint is Redis-cached (30 min TTL) and otherwise does
    // 5 parallel DB queries. 800ms p95 is the Phase D pass/fail line; abort the
    // run if it blows past 3s for a sustained period (clearly saturated).
    'home_bootstrap_latency': ['p(95)<800', 'p(99)<2000'],
    'http_req_duration{endpoint:bootstrap}': [
      { threshold: 'p(95)<800', abortOnFail: false },
      { threshold: 'p(95)<3000', abortOnFail: true, delayAbortEval: '1m' },
    ],
    'home_bootstrap_error_rate': ['rate<0.01'],         // <1% functional errors
    'http_req_failed{endpoint:bootstrap}': ['rate<0.02'], // <2% transport/5xx
    // --- Follow-up call ------------------------------------------------------
    'home_followup_latency': ['p(95)<1200'],
    'http_req_failed{endpoint:today}': ['rate<0.03'],
    // --- Whole flow ----------------------------------------------------------
    'checks': ['rate>0.98'],
  },
  // Keep summary output focused; full per-endpoint metrics still print.
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

// =============================================================================
// VU lifecycle
// =============================================================================

export function setup() {
  console.log(`[loadtest] BASE_URL  = ${BASE_URL}`);
  console.log(`[loadtest] token pool size = ${TOKENS.length}`);
  console.log(`[loadtest] profile   = ${SMOKE ? 'SMOKE' : 'FULL RAMP (100->1k->5k->10k)'}`);
  if (TOKENS.length < 50 && !SMOKE) {
    console.warn(
      '[loadtest] WARNING: small token pool for a 10k-VU run. Many VUs will ' +
      'share the same user, inflating the Redis cache-hit rate and ' +
      'under-measuring the cold path. Mint >= ~200 tokens for a realistic mix.'
    );
  }
  // Quick reachability probe so a wrong BASE_URL fails in setup, not mid-ramp.
  const ping = http.get(`${BASE_URL}/`, { timeout: '10s' });
  if (ping.status === 0) {
    fail(`[loadtest] Cannot reach ${BASE_URL}/ — check the host is up and correct.`);
  }
  console.log(`[loadtest] health probe GET / -> ${ping.status}`);
  return {}; // nothing to pass through
}

export default function () {
  // Pick a token for this iteration. Spreading across the pool by VU id keeps
  // a given VU mostly stable (realistic — one device = one session) while the
  // fleet still exercises many distinct users.
  const entry = TOKENS[(__VU + __ITER) % TOKENS.length];
  const { token, userId } = parseTokenEntry(entry);

  if (!userId) {
    // A token with no derivable user_id can't hit bootstrap — count and skip.
    bootstrapErrors.add(1);
    check(null, { 'token has resolvable user_id': () => false });
    return;
  }

  const authHeaders = {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
    },
  };

  // ── Request 1: the Home bootstrap (the hot path under test) ───────────────
  const bootstrapRes = http.get(
    `${BASE_URL}/api/v1/home/bootstrap?user_id=${encodeURIComponent(userId)}`,
    {
      ...authHeaders,
      // `tags` isolate this request's metrics from the follow-up call so
      // http_req_duration{endpoint:bootstrap} is a clean signal.
      tags: { endpoint: 'bootstrap', flow: 'home_open' },
      timeout: '30s',
    }
  );

  bootstrapLatency.add(bootstrapRes.timings.duration);

  let bootstrapBody = null;
  try {
    bootstrapBody = bootstrapRes.json();
  } catch (e) {
    bootstrapBody = null;
  }

  const bootstrapOk = check(
    bootstrapRes,
    {
      'bootstrap: status is 200': (r) => r.status === 200,
      'bootstrap: not a 401 (token valid)': (r) => r.status !== 401,
      'bootstrap: not a 5xx': (r) => r.status < 500,
      // Body shape — BootstrapResponse always serializes these top-level keys.
      'bootstrap: body has nutrition_summary': () =>
        bootstrapBody !== null && 'nutrition_summary' in bootstrapBody,
      'bootstrap: body has hydration': () =>
        bootstrapBody !== null && 'hydration' in bootstrapBody,
      'bootstrap: body has xp': () =>
        bootstrapBody !== null && 'xp' in bootstrapBody,
      'bootstrap: body has gym_profile': () =>
        bootstrapBody !== null && 'gym_profile' in bootstrapBody,
      // today_workout is nullable but the key must be present.
      'bootstrap: body has today_workout key': () =>
        bootstrapBody !== null && 'today_workout' in bootstrapBody,
    },
    { endpoint: 'bootstrap' }
  );

  // A request counts as a functional error if status != 200 OR the body shape
  // is wrong. http_req_failed already tracks transport/5xx separately.
  bootstrapErrors.add(!bootstrapOk);

  // Cache-hit telemetry: the endpoint logs CACHE HIT/SET server-side, but from
  // the client we approximate it by latency band — a Redis hit returns in tens
  // of ms, a cold 5-query fan-out is hundreds of ms. This is a coarse proxy;
  // the authoritative number is Redis INFO stats (see README.md).
  if (bootstrapRes.status === 200) {
    if (bootstrapRes.timings.duration < 80) cacheHits.add(1);
    else cacheMisses.add(1);
  }

  // Realistic think-time: the user looks at the Home screen before tapping in.
  sleep(THINK_MIN + Math.random() * (THINK_MAX - THINK_MIN));

  // ── Request 2: realistic Home follow-up — the hero carousel "today" call ──
  // Tapping the hero workout card triggers GET /workouts/today.
  const todayRes = http.get(
    `${BASE_URL}/api/v1/workouts/today?user_id=${encodeURIComponent(userId)}`,
    {
      ...authHeaders,
      tags: { endpoint: 'today', flow: 'home_open' },
      timeout: '30s',
    }
  );
  followupLatency.add(todayRes.timings.duration);

  check(
    todayRes,
    {
      'today: status is 200': (r) => r.status === 200,
      'today: not a 5xx': (r) => r.status < 500,
    },
    { endpoint: 'today' }
  );

  // Pacing between iterations so a single VU models one user re-opening Home
  // periodically rather than hammering in a tight loop.
  sleep(THINK_MIN + Math.random() * (THINK_MAX - THINK_MIN));
}

// =============================================================================
// Summary — write both a human-readable stdout summary and a JSON artifact.
// =============================================================================

export function handleSummary(data) {
  return {
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
    'loadtest-summary.json': JSON.stringify(data, null, 2),
  };
}
