import { Fragment, useEffect } from 'react';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

/* ────────────────────────────────────────────────────────────
   MCP Docs — setup guide + tool reference for connecting an
   MCP client (Claude Desktop, Claude Code, Cursor) to a user's
   own Zealova account. Static reference content, no client state.
   ──────────────────────────────────────────────────────────── */

type ToolRow = { name: string; scope: string; write?: boolean; confirm?: string; desc: string };
type ToolGroup = { group: string; rows: ToolRow[] };

const TOOL_GROUPS: ToolGroup[] = [
  {
    group: 'Workouts',
    rows: [
      { name: 'get_today_workout', scope: 'read:workouts', desc: "Today's scheduled workout, if any" },
      { name: 'get_workout_history', scope: 'read:workouts', desc: 'Past workouts in a date range' },
      { name: 'log_completed_set', scope: 'write:logs', write: true, desc: 'Log reps/weight/RPE for a set' },
      { name: 'adjust_set_weight', scope: 'write:logs', write: true, desc: 'Nudge a target weight up or down' },
      { name: 'modify_workout', scope: 'write:workouts', write: true, confirm: 'on remove', desc: 'Add/remove/replace/reschedule an exercise' },
      { name: 'generate_workout_plan', scope: 'write:workouts', write: true, confirm: 'on replace', desc: 'Generate a new AI workout' },
    ],
  },
  {
    group: 'Programs',
    rows: [
      { name: 'get_available_programs', scope: 'read:programs', desc: 'Browse the published program library' },
      { name: 'get_program_details', scope: 'read:programs', desc: 'Full days/exercises preview of one program' },
      { name: 'get_program_schedule', scope: 'read:programs', desc: 'Multi-week schedule for a program variant' },
      { name: 'get_my_assigned_programs', scope: 'read:programs', desc: "What's currently on your schedule" },
      { name: 'assign_program_to_schedule', scope: 'write:programs', write: true, confirm: 'as primary', desc: 'Start a program' },
    ],
  },
  {
    group: 'Nutrition',
    rows: [
      { name: 'log_meal_from_text', scope: 'write:logs', write: true, desc: 'Log a meal from a description' },
      { name: 'log_meal_from_image', scope: 'write:logs', write: true, desc: 'Log a meal from a photo URL' },
      { name: 'get_nutrition_summary', scope: 'read:nutrition', desc: 'Daily macro/calorie totals' },
      { name: 'search_food', scope: 'read:nutrition', desc: 'Search the food database' },
      { name: 'log_water', scope: 'write:logs', write: true, desc: 'Log water intake (ml)' },
      { name: 'get_recent_meals', scope: 'read:nutrition', desc: 'Most recently logged meals' },
      { name: 'get_favorite_foods', scope: 'read:nutrition', desc: 'Saved / favorite foods' },
      { name: 'suggest_recipes_from_fridge', scope: 'read:nutrition', desc: 'Recipes from a fridge photo and/or ingredient list' },
    ],
  },
  {
    group: 'Fasting',
    rows: [
      { name: 'start_fast', scope: 'write:fasting', write: true, desc: 'Start a new fast' },
      { name: 'end_fast', scope: 'write:fasting', write: true, desc: 'End the active fast, get results + streak' },
      { name: 'get_fasting_status', scope: 'read:fasting', desc: 'Active fast (if any) + current streak' },
      { name: 'get_fasting_history', scope: 'read:fasting', desc: 'Past fasts' },
    ],
  },
  {
    group: 'Coach & body',
    rows: [
      { name: 'chat_with_coach', scope: 'chat:coach', desc: 'Talk to your AI coach agents' },
      { name: 'get_readiness_score', scope: 'read:scores', desc: 'Recovery / readiness score' },
      { name: 'get_strength_scores', scope: 'read:scores', desc: 'Strength score per muscle group' },
      { name: 'get_streak_and_habits', scope: 'read:scores', desc: 'Workout streak + active habits' },
      { name: 'get_progress_photos', scope: 'read:profile', desc: 'Recent progress photos' },
      { name: 'get_user_profile', scope: 'read:profile', desc: 'Profile, goals, preferences' },
      { name: 'log_body_weight', scope: 'write:logs', write: true, desc: 'Log a body weight measurement' },
      { name: 'update_user_goal', scope: 'write:logs', write: true, desc: 'Change your primary goal' },
    ],
  },
  {
    group: 'Exports',
    rows: [
      { name: 'export_user_data', scope: 'export:data', write: true, desc: 'Export your raw data' },
      { name: 'generate_report', scope: 'export:data', write: true, desc: 'Generate a formatted report' },
    ],
  },
];

const PROMPTS: { group: string; items: { quote: string; tools: string[] }[] }[] = [
  {
    group: 'Workouts',
    items: [
      { quote: "What's my workout today, and swap the barbell row for something with dumbbells.", tools: ['get_today_workout', 'modify_workout'] },
      { quote: 'Generate me a new 4-day upper/lower split.', tools: ['generate_workout_plan'] },
    ],
  },
  {
    group: 'Programs',
    items: [
      { quote: 'Show me beginner strength programs, 3 days a week.', tools: ['get_available_programs'] },
      { quote: 'Start the HYROX prep program as my primary.', tools: ['assign_program_to_schedule'] },
    ],
  },
  {
    group: 'Nutrition',
    items: [
      { quote: 'I had 2 eggs and toast for breakfast, log it.', tools: ['log_meal_from_text'] },
      { quote: "Here's a photo of my fridge — what can I cook that's high protein?", tools: ['suggest_recipes_from_fridge'] },
    ],
  },
  {
    group: 'Fasting & coach',
    items: [
      { quote: 'Start a 16:8 fast for me.', tools: ['start_fast'] },
      { quote: 'How\'s my recovery — should I train legs today?', tools: ['get_readiness_score', 'chat_with_coach'] },
    ],
  },
];

function ScopeBadge({ scope, write }: { scope: string; write?: boolean }) {
  return (
    <code
      className={`inline-block rounded px-1.5 py-0.5 text-[11px] font-mono border ${
        write ? 'text-orange-300 border-orange-500/30 bg-orange-500/10' : 'text-cyan-300 border-cyan-500/30 bg-cyan-500/10'
      }`}
    >
      {scope}
    </code>
  );
}

export default function MCPDocs() {
  const canonical = `${BRANDING.websiteUrl}/mcp/docs`;

  useEffect(() => {
    document.title = `MCP Setup Guide | ${BRANDING.appName}`;
    const setMeta = (name: string, value: string, isProperty = false) => {
      const attr = isProperty ? 'property' : 'name';
      let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${name}"]`);
      if (!el) {
        el = document.createElement('meta');
        el.setAttribute(attr, name);
        document.head.appendChild(el);
      }
      el.content = value;
    };
    const description = `Connect Claude Desktop, Claude Code, or Cursor to your ${BRANDING.appName} account via MCP — full setup guide and a reference for all 33 tools.`;
    setMeta('description', description);
    setMeta('og:title', `MCP Setup Guide | ${BRANDING.appName}`, true);
    setMeta('og:description', description, true);
    setMeta('og:url', canonical, true);
    setMeta('og:type', 'article', true);

    let canonicalLink = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.rel = 'canonical';
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.href = canonical;
  }, [canonical]);

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'TechArticle',
    headline: `Connecting ${BRANDING.appName} to Claude via MCP`,
    description: `Setup guide and tool reference for the ${BRANDING.appName} MCP server.`,
    author: { '@type': 'Organization', name: BRANDING.appName },
  };

  return (
    <div className="min-h-screen bg-[#050505] text-white">
      <MarketingNav />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      {/* ── Hero ── */}
      <section className="relative pt-28 sm:pt-32 pb-16 px-4 sm:px-6 bg-[radial-gradient(60%_40%_at_50%_0%,rgba(255,122,0,0.07),transparent)]">
        <div className="max-w-[820px] mx-auto">
          <p className="condensed-kicker text-xs text-volt-500 mb-4">Setup guide</p>
          <h1 className="display-heading text-5xl sm:text-7xl text-white mb-5">
            Connect {BRANDING.appName} to Claude
          </h1>
          <p className="text-[15px] text-zinc-400 leading-relaxed mb-6 max-w-[62ch]">
            Give Claude Desktop, Claude Code, or Cursor read/write access to your own workouts, nutrition,
            programs, and fasting data — through a real MCP server, not a demo.
          </p>
          <div className="kinetic-rule mb-10" />

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-px bg-white/10 rounded-xl overflow-hidden border border-white/10">
            {[
              ['Requires', 'Yearly subscription'],
              ['Client', 'Claude Desktop, Claude Code, or Cursor'],
              ['Time', '~2 minutes'],
            ].map(([label, val]) => (
              <div key={label} className="bg-[#0D0D0D] px-5 py-4">
                <div className="text-[11px] uppercase tracking-wide text-zinc-500 font-semibold">{label}</div>
                <div className="text-sm mt-1 font-medium text-white">{val}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Connect ── */}
      <section className="px-4 sm:px-6 py-16 border-t border-white/10">
        <div className="max-w-[820px] mx-auto">
          <h2 className="condensed-kicker text-sm text-volt-500 mb-6">Connect</h2>

          <ol className="space-y-8">
            <li className="grid grid-cols-[36px_1fr] gap-4">
              <div className="w-9 h-9 rounded-lg bg-volt-500/15 text-volt-500 font-mono text-sm font-bold flex items-center justify-center">1</div>
              <div>
                <h3 className="font-semibold text-white mb-1.5">Create a connection in the app</h3>
                <p className="text-sm text-zinc-400 leading-relaxed">
                  Open the {BRANDING.appName} app → <code className="text-zinc-300 bg-white/5 px-1.5 py-0.5 rounded text-[13px]">Settings → AI Integrations</code> (under Personalization)
                  → <strong className="text-white">Create Connection</strong>. Pick <strong className="text-white">Quick Setup</strong> for
                  a safe read-only start, or <strong className="text-white">Custom</strong> to also grant write access — logging, program
                  assignment, fasting, coach chat.
                </p>
              </div>
            </li>

            <li className="grid grid-cols-[36px_1fr] gap-4">
              <div className="w-9 h-9 rounded-lg bg-volt-500/15 text-volt-500 font-mono text-sm font-bold flex items-center justify-center">2</div>
              <div>
                <h3 className="font-semibold text-white mb-1.5">Copy the generated config</h3>
                <p className="text-sm text-zinc-400 leading-relaxed mb-3">
                  The app shows a one-time "Connection Ready" screen with a ready-to-paste JSON block. This is the only time the token
                  is shown in plaintext — copy it now.
                </p>
                <pre className="rounded-lg bg-[#0A0A0A] border border-white/10 p-4 text-[12.5px] font-mono text-zinc-300 overflow-x-auto leading-relaxed">
{`{
  "mcpServers": {
    "zealova": {
      "url": "https://mcp.zealova.com/mcp",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer fwz_pat_••••••••••••"
      }
    }
  }
}`}
                </pre>
              </div>
            </li>

            <li className="grid grid-cols-[36px_1fr] gap-4">
              <div className="w-9 h-9 rounded-lg bg-volt-500/15 text-volt-500 font-mono text-sm font-bold flex items-center justify-center">3</div>
              <div>
                <h3 className="font-semibold text-white mb-1.5">Paste it into your client</h3>

                <div className="space-y-3 mt-3">
                  <div className="rounded-lg border border-white/10 bg-[#0D0D0D] p-4">
                    <div className="font-semibold text-sm text-white mb-1.5">Claude Desktop</div>
                    <p className="text-sm text-zinc-400">
                      Edit the config file directly, merge the block above into <code className="text-zinc-300">mcpServers</code>, save.
                    </p>
                    <p className="text-[13px] text-zinc-500 mt-1.5 font-mono">macOS: ~/Library/Application Support/Claude/claude_desktop_config.json</p>
                    <p className="text-[13px] text-zinc-500 font-mono">Windows: %APPDATA%\Claude\claude_desktop_config.json</p>
                  </div>

                  <div className="rounded-lg border border-white/10 bg-[#0D0D0D] p-4">
                    <div className="font-semibold text-sm text-white mb-1.5">Cursor</div>
                    <p className="text-sm text-zinc-400">
                      <code className="text-zinc-300">Settings → MCP → Add Server</code> → paste the same block.
                    </p>
                  </div>

                  <div className="rounded-lg border border-white/10 bg-[#0D0D0D] p-4">
                    <div className="font-semibold text-sm text-white mb-1.5">Claude Code CLI — the fast path</div>
                    <p className="text-sm text-zinc-400 mb-2">
                      Skip steps 1–2 and run this instead, then authenticate:
                    </p>
                    <pre className="rounded bg-[#0A0A0A] border border-white/10 p-3 text-[12.5px] font-mono text-zinc-300 overflow-x-auto mb-2">
{`claude mcp add --transport http zealova https://mcp.zealova.com/mcp
claude mcp login zealova`}
                    </pre>
                    <p className="text-[13px] text-zinc-500">
                      The first command only registers the server — it never triggers sign-in itself. <code className="text-zinc-300">login</code> is
                      the separate step that opens your browser to approve the connection. Run <code className="text-zinc-300">claude mcp list</code> afterward
                      to confirm it shows <span className="text-emerald-400">Connected</span>.
                    </p>
                  </div>
                </div>
              </div>
            </li>

            <li className="grid grid-cols-[36px_1fr] gap-4">
              <div className="w-9 h-9 rounded-lg bg-volt-500/15 text-volt-500 font-mono text-sm font-bold flex items-center justify-center">4</div>
              <div>
                <h3 className="font-semibold text-white mb-1.5">Restart and verify</h3>
                <p className="text-sm text-zinc-400 leading-relaxed">
                  Fully quit and reopen Claude Desktop / Cursor — config changes aren't picked up live. Then just ask it something:
                </p>
                <pre className="rounded-lg bg-[#0A0A0A] border border-white/10 p-4 text-[13px] font-mono text-zinc-300 mt-3">
{`> What's my workout today?`}
                </pre>
              </div>
            </li>
          </ol>
        </div>
      </section>

      {/* ── Try it ── */}
      <section className="px-4 sm:px-6 py-16 border-t border-white/10">
        <div className="max-w-[820px] mx-auto">
          <h2 className="condensed-kicker text-sm text-volt-500 mb-2">Try it</h2>
          <p className="text-sm text-zinc-400 mb-8 max-w-[62ch]">
            Once connected, here's what a real conversation can look like — grouped by what it touches.
          </p>

          <div className="space-y-8">
            {PROMPTS.map((g) => (
              <div key={g.group}>
                <div className="text-xs font-bold uppercase tracking-wide text-cyan-400 mb-3">{g.group}</div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {g.items.map((p) => (
                    <div key={p.quote} className="rounded-lg border border-white/10 bg-[#0D0D0D] p-4">
                      <div className="text-sm italic text-zinc-200">"{p.quote}"</div>
                      <div className="mt-2 flex flex-wrap gap-1.5 text-[11px] text-zinc-500">
                        calls
                        {p.tools.map((t) => (
                          <code key={t} className="bg-cyan-500/10 text-cyan-300 rounded px-1.5 py-0.5">{t}</code>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Tool reference ── */}
      <section className="px-4 sm:px-6 py-16 border-t border-white/10">
        <div className="max-w-[900px] mx-auto">
          <h2 className="condensed-kicker text-sm text-volt-500 mb-2">Full tool reference</h2>
          <p className="text-sm text-zinc-400 mb-8 max-w-[68ch]">
            All 33 tools, grouped by domain. <ScopeBadge scope="read:*" /> scopes are safe defaults;{' '}
            <ScopeBadge scope="write:*" write /> scopes change something. A confirm note means Claude has to double-check with you before it runs.
          </p>

          <div className="overflow-x-auto rounded-xl border border-white/10">
            <table className="w-full text-sm min-w-[640px]">
              <thead>
                <tr className="bg-white/5 text-left text-[11px] uppercase tracking-wide text-zinc-500">
                  <th className="px-4 py-2.5 font-semibold">Tool</th>
                  <th className="px-4 py-2.5 font-semibold">Scope</th>
                  <th className="px-4 py-2.5 font-semibold">What it does</th>
                </tr>
              </thead>
              <tbody>
                {TOOL_GROUPS.map((g) => (
                  <Fragment key={g.group}>
                    <tr className="bg-white/[0.03]">
                      <td colSpan={3} className="px-4 py-2 text-[11px] font-bold uppercase tracking-wide text-volt-500">
                        {g.group}
                      </td>
                    </tr>
                    {g.rows.map((r) => (
                      <tr key={r.name} className="border-t border-white/5 hover:bg-white/[0.02]">
                        <td className="px-4 py-2.5 font-mono text-[13px] text-zinc-200">{r.name}</td>
                        <td className="px-4 py-2.5"><ScopeBadge scope={r.scope} write={r.write} /></td>
                        <td className="px-4 py-2.5 text-zinc-400">
                          {r.desc}
                          {r.confirm && <span className="ml-2 text-[11px] text-orange-400 font-semibold">confirm {r.confirm}</span>}
                        </td>
                      </tr>
                    ))}
                  </Fragment>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* ── Security & limits ── */}
      <section className="px-4 sm:px-6 py-16 border-t border-white/10">
        <div className="max-w-[820px] mx-auto">
          <h2 className="condensed-kicker text-sm text-volt-500 mb-6">Security &amp; limits</h2>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-px bg-white/10 rounded-xl overflow-hidden border border-white/10 mb-6">
            {[
              ['30', 'calls / minute'],
              ['500', 'calls / hour'],
              ['25', 'writes / hour'],
              ['10', 'coach chats / hour'],
            ].map(([num, label]) => (
              <div key={label} className="bg-[#0D0D0D] px-4 py-4 text-center">
                <div className="font-mono text-2xl font-bold text-volt-500 tabular-nums">{num}</div>
                <div className="text-[12px] text-zinc-500 mt-1">{label}</div>
              </div>
            ))}
          </div>

          <div className="rounded-lg border border-orange-500/30 bg-orange-500/[0.06] p-4 mb-4">
            <div className="font-semibold text-sm text-orange-300 mb-1">Treat the token like a password</div>
            <p className="text-sm text-zinc-400">
              It's shown once, at creation. Anyone with it can act within the scopes you granted, for as long as the connection
              exists. Revoke anytime from <code className="text-zinc-300">Settings → AI Integrations</code>.
            </p>
          </div>

          <div className="rounded-lg border border-cyan-500/30 bg-cyan-500/[0.06] p-4">
            <div className="font-semibold text-sm text-cyan-300 mb-1">Auto-revoke on abuse</div>
            <p className="text-sm text-zinc-400">
              Cross ~200 tool calls a minute, or 50 meal-logs in 5 minutes, and the whole connection is revoked automatically —
              you'd need to reconnect from the app.
            </p>
          </div>
        </div>
      </section>

      {/* ── Troubleshooting ── */}
      <section className="px-4 sm:px-6 py-16 border-t border-white/10">
        <div className="max-w-[820px] mx-auto">
          <h2 className="condensed-kicker text-sm text-volt-500 mb-6">If something doesn't work</h2>
          <div className="space-y-5">
            {[
              ['Claude says it can\'t find any Zealova tools', 'Fully quit the client (not just close the window) after editing the config, and reopen. Config changes don\'t hot-reload.'],
              ['A write call keeps asking me to confirm', 'That\'s intentional for anything with real consequences — replacing your workout plan, ending your active program. Re-send the same request; Claude includes the confirmation token automatically.'],
              ['I want to revoke access', 'Settings → AI Integrations → tap the connection → Disconnect. Takes effect immediately.'],
            ].map(([q, a]) => (
              <div key={q} className="border-t border-white/10 pt-5">
                <h3 className="font-semibold text-sm text-white mb-1">{q}</h3>
                <p className="text-sm text-zinc-400">{a}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
