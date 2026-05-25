/**
 * /share — Web upload page for the Imports feature.
 *
 * Mirrors the iOS / Android share-sheet flow for desktop browsers. Lets
 * users drop a file, paste a URL, or paste text and routes it through
 * the same `/api/v1/share/import-*` endpoints.
 *
 * Auth: uses the existing Supabase session token from localStorage. If
 * the visitor isn't signed in, we surface a "Sign in to import" CTA.
 */
import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';

const BACKEND =
  (typeof import.meta !== 'undefined' && (import.meta as any).env?.VITE_BACKEND_BASE_URL) ||
  'https://api.zealova.com';

type Event = { stage: string; [k: string]: any };

export default function Share() {
  const [token, setToken] = useState<string | null>(null);
  const [pasted, setPasted] = useState('');
  const [url, setUrl] = useState('');
  const [events, setEvents] = useState<Event[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const dropRef = useRef<HTMLDivElement | null>(null);

  // ---- Auth lookup ---------------------------------------------------------

  useEffect(() => {
    try {
      const raw = localStorage.getItem(
        Object.keys(localStorage).find((k) => k.startsWith('sb-') && k.endsWith('-auth-token')) ||
          ''
      );
      if (raw) {
        const parsed = JSON.parse(raw);
        const access = parsed?.access_token || parsed?.currentSession?.access_token;
        if (access) setToken(access);
      }
    } catch {/* signed-out path */}
  }, []);

  // ---- SSE plumbing --------------------------------------------------------

  async function streamPost(path: string, init: RequestInit) {
    setBusy(true);
    setError(null);
    setEvents([]);
    try {
      const res = await fetch(`${BACKEND}/api/v1${path}`, init);
      if (!res.ok || !res.body) {
        setError(`Server returned ${res.status}`);
        return;
      }
      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buf = '';
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += decoder.decode(value, { stream: true });
        const lines = buf.split('\n');
        buf = lines.pop() || '';
        for (const ln of lines) {
          if (ln.startsWith('data:')) {
            try {
              const obj = JSON.parse(ln.slice(5).trim()) as Event;
              setEvents((evts) => [...evts, obj]);
            } catch {/* malformed line */}
          }
        }
      }
    } catch (e: any) {
      setError(e?.message || 'Network error');
    } finally {
      setBusy(false);
    }
  }

  // ---- Submit handlers -----------------------------------------------------

  function commonHeaders(extra?: Record<string, string>): HeadersInit {
    return {
      ...(extra || {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      Accept: 'text/event-stream',
    };
  }

  function submitUrl() {
    if (!url.trim()) return;
    return streamPost('/share/fetch-url', {
      method: 'POST',
      headers: commonHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({ url: url.trim() }),
    });
  }

  function submitText() {
    if (!pasted.trim()) return;
    return streamPost('/share/import-text', {
      method: 'POST',
      headers: commonHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({ text: pasted, source_hint: 'web' }),
    });
  }

  async function submitFile(file: File) {
    const ext = (file.name.split('.').pop() || '').toLowerCase();
    const isPdf = file.type === 'application/pdf' || ext === 'pdf';
    const isAudio = file.type.startsWith('audio/') || ['m4a', 'mp3', 'wav', 'caf', 'aac'].includes(ext);
    const path = isPdf
      ? '/share/import-pdf'
      : isAudio
        ? '/share/import-audio'
        : '/share/classify';
    const form = new FormData();
    form.append('file', file);
    if (path === '/share/classify') {
      form.append('source_origin', 'web');
      form.append('track', 'true');
    }
    return streamPost(path, {
      method: 'POST',
      headers: commonHeaders(),
      body: form,
    });
  }

  // ---- Drag-drop -----------------------------------------------------------

  useEffect(() => {
    const el = dropRef.current;
    if (!el) return;
    const onOver = (e: DragEvent) => {
      e.preventDefault();
    };
    const onDrop = (e: DragEvent) => {
      e.preventDefault();
      const files = e.dataTransfer?.files;
      if (!files || files.length === 0) return;
      submitFile(files[0]);
    };
    el.addEventListener('dragover', onOver);
    el.addEventListener('drop', onDrop);
    return () => {
      el.removeEventListener('dragover', onOver);
      el.removeEventListener('drop', onDrop);
    };
  }, [token]);

  // ---- Render --------------------------------------------------------------

  if (!token) {
    return (
      <div className="max-w-2xl mx-auto p-8">
        <h1 className="text-3xl font-bold mb-4">Imports</h1>
        <p className="mb-4">
          Sign in to import workouts, recipes, voice memos, PDFs, and URLs into Zealova.
        </p>
        <Link to="/" className="text-blue-600 underline">
          Sign in
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-2">Send to Zealova</h1>
      <p className="text-gray-600 mb-6">
        Drag a file in, paste a URL, or paste any text from ChatGPT, Claude, Perplexity, or your notes.
      </p>

      {/* Drop zone */}
      <div
        ref={dropRef}
        className="border-2 border-dashed rounded-xl p-12 text-center mb-6"
      >
        <div className="text-lg font-medium mb-2">Drop a file here</div>
        <div className="text-sm text-gray-500">
          Images · Videos · Audio · PDFs · up to 500 MB
        </div>
        <input
          type="file"
          accept="image/*,video/*,audio/*,application/pdf"
          className="mt-4"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) submitFile(f);
          }}
        />
      </div>

      {/* URL */}
      <div className="mb-6">
        <label className="block text-sm font-medium mb-2">Paste a URL</label>
        <div className="flex gap-2">
          <input
            type="url"
            placeholder="https://youtube.com/watch?v=…"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            className="flex-1 border rounded px-3 py-2"
          />
          <button
            disabled={busy || !url}
            onClick={submitUrl}
            className="bg-black text-white px-4 py-2 rounded disabled:opacity-50"
          >
            Import
          </button>
        </div>
      </div>

      {/* Text */}
      <div className="mb-6">
        <label className="block text-sm font-medium mb-2">Paste text</label>
        <textarea
          rows={6}
          placeholder="Paste a workout from ChatGPT, a recipe, a tip from Perplexity…"
          value={pasted}
          onChange={(e) => setPasted(e.target.value)}
          className="w-full border rounded px-3 py-2"
        />
        <button
          disabled={busy || !pasted.trim()}
          onClick={submitText}
          className="bg-black text-white px-4 py-2 rounded disabled:opacity-50 mt-2"
        >
          Import text
        </button>
      </div>

      {/* Progress + result */}
      {busy && <div className="text-sm text-gray-500">Working…</div>}
      {error && <div className="text-red-600 text-sm">{error}</div>}
      {events.length > 0 && (
        <div className="border rounded p-4 bg-gray-50 mt-4">
          {events.map((e, i) => (
            <div key={i} className="text-sm font-mono">
              {e.stage}
              {e.intent ? ` → ${e.intent}` : ''}
              {e.message ? ` — ${e.message}` : ''}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
