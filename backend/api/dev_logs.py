"""
Dev Log Dashboard — real-time request log viewer for local development.

Only available when DEBUG=true. Serves:
  GET /dev/logs      — HTML dashboard with live-updating log stream
  GET /dev/logs/sse  — Server-Sent Events endpoint for real-time logs
"""
import asyncio
import json
import time
from collections import deque
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, StreamingResponse

from core import branding

router = APIRouter(prefix="/dev", tags=["dev"])

# In-memory circular buffer of recent log entries (last 200)
_log_buffer: deque[dict] = deque(maxlen=200)

# SSE subscribers waiting for new logs
_subscribers: list[asyncio.Queue] = []


def push_log_entry(
    method: str,
    path: str,
    status_code: int,
    duration_ms: float,
    user_id: Optional[str] = None,
    request_id: Optional[str] = None,
    query: str = "",
    error: Optional[str] = None,
):
    """Called from LoggingMiddleware to record a completed request."""
    entry = {
        "timestamp": datetime.now().strftime("%H:%M:%S.%f")[:-3],
        "method": method,
        "path": path,
        "query": query,
        "status": status_code,
        "duration_ms": round(duration_ms),
        "user_id": user_id or "",
        "request_id": request_id or "",
        "error": error or "",
    }
    _log_buffer.append(entry)
    # Notify all SSE subscribers
    for q in _subscribers:
        try:
            q.put_nowait(entry)
        except asyncio.QueueFull:
            pass  # Drop if subscriber is slow


@router.get("/logs", response_class=HTMLResponse)
async def dev_logs_dashboard():
    """Serve the dev log dashboard HTML page."""
    return _DASHBOARD_HTML


@router.get("/logs/sse")
async def dev_logs_sse(request: Request):
    """SSE endpoint that streams log entries in real time."""
    queue: asyncio.Queue = asyncio.Queue(maxsize=100)
    _subscribers.append(queue)

    async def event_stream():
        try:
            # Send existing buffer as initial batch
            for entry in list(_log_buffer):
                yield f"data: {json.dumps(entry)}\n\n"
            # Stream new entries
            while True:
                if await request.is_disconnected():
                    break
                try:
                    entry = await asyncio.wait_for(queue.get(), timeout=30)
                    yield f"data: {json.dumps(entry)}\n\n"
                except asyncio.TimeoutError:
                    # Send keepalive
                    yield ": keepalive\n\n"
        finally:
            _subscribers.remove(queue)

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


_DASHBOARD_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__BRAND__ Dev Logs</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace;
    background: #0d1117;
    color: #c9d1d9;
    font-size: 13px;
  }
  .header {
    background: #161b22;
    border-bottom: 1px solid #30363d;
    padding: 12px 20px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    position: sticky;
    top: 0;
    z-index: 10;
  }
  .header h1 {
    font-size: 16px;
    font-weight: 600;
    color: #58a6ff;
  }
  .header .status {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 12px;
    color: #8b949e;
  }
  .header .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #3fb950;
    animation: pulse 2s infinite;
  }
  .header .dot.disconnected { background: #f85149; animation: none; }
  @keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.5; } }
  .controls {
    display: flex;
    gap: 8px;
    padding: 8px 20px;
    background: #161b22;
    border-bottom: 1px solid #30363d;
  }
  .controls input {
    background: #0d1117;
    border: 1px solid #30363d;
    color: #c9d1d9;
    padding: 4px 10px;
    border-radius: 6px;
    font-family: inherit;
    font-size: 12px;
    flex: 1;
    max-width: 300px;
  }
  .controls input:focus { outline: none; border-color: #58a6ff; }
  .controls button {
    background: #21262d;
    border: 1px solid #30363d;
    color: #c9d1d9;
    padding: 4px 12px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 12px;
  }
  .controls button:hover { background: #30363d; }
  .log-table {
    width: 100%;
    border-collapse: collapse;
  }
  .log-table th {
    text-align: left;
    padding: 6px 12px;
    background: #161b22;
    border-bottom: 1px solid #30363d;
    color: #8b949e;
    font-weight: 500;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    position: sticky;
    top: 85px;
    z-index: 5;
  }
  .log-table td {
    padding: 5px 12px;
    border-bottom: 1px solid #21262d;
    white-space: nowrap;
  }
  .log-table tr:hover { background: #161b22; }
  .log-table tr.new { animation: flash 1s ease-out; }
  @keyframes flash { from { background: #1f3a1f; } to { background: transparent; } }
  .method { font-weight: 700; min-width: 50px; display: inline-block; }
  .method.GET { color: #3fb950; }
  .method.POST { color: #58a6ff; }
  .method.PUT { color: #d29922; }
  .method.PATCH { color: #d29922; }
  .method.DELETE { color: #f85149; }
  .status-badge {
    padding: 1px 8px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 12px;
  }
  .status-2xx { background: #1b3a2a; color: #3fb950; }
  .status-3xx { background: #2a2a1b; color: #d29922; }
  .status-4xx { background: #3a2a1b; color: #d29922; }
  .status-5xx { background: #3a1b1b; color: #f85149; }
  .duration { color: #8b949e; }
  .duration.slow { color: #d29922; }
  .duration.very-slow { color: #f85149; }
  .path { color: #c9d1d9; }
  .query { color: #6e7681; }
  .user-id { color: #8b949e; font-size: 11px; }
  .req-id { color: #6e7681; font-size: 11px; }
  .empty {
    text-align: center;
    padding: 60px 20px;
    color: #484f58;
  }
  .count { color: #8b949e; font-size: 12px; }
</style>
</head>
<body>
<div class="header">
  <h1>__BRAND__ Dev Logs</h1>
  <div style="display:flex;align-items:center;gap:16px;">
    <span class="count" id="count">0 requests</span>
    <div class="status">
      <div class="dot" id="dot"></div>
      <span id="conn-status">Connected</span>
    </div>
  </div>
</div>
<div class="controls">
  <input type="text" id="filter" placeholder="Filter by path, method, or status..." />
  <button onclick="clearLogs()">Clear</button>
  <button onclick="toggleScroll()" id="scroll-btn">Auto-scroll: ON</button>
</div>
<table class="log-table">
  <thead>
    <tr>
      <th>Time</th>
      <th>Method</th>
      <th>Path</th>
      <th>Status</th>
      <th>Duration</th>
      <th>User</th>
      <th>Req ID</th>
    </tr>
  </thead>
  <tbody id="logs">
    <tr class="empty" id="empty-row"><td colspan="7">Waiting for requests...</td></tr>
  </tbody>
</table>

<script>
let autoScroll = true;
let entries = [];
const tbody = document.getElementById('logs');
const filterInput = document.getElementById('filter');
const countEl = document.getElementById('count');
const dot = document.getElementById('dot');
const connStatus = document.getElementById('conn-status');

function statusClass(s) {
  if (s < 300) return 'status-2xx';
  if (s < 400) return 'status-3xx';
  if (s < 500) return 'status-4xx';
  return 'status-5xx';
}

function durationClass(ms) {
  if (ms > 5000) return 'very-slow';
  if (ms > 1000) return 'slow';
  return '';
}

function addRow(e, animate) {
  const empty = document.getElementById('empty-row');
  if (empty) empty.remove();

  const filter = filterInput.value.toLowerCase();
  if (filter && !`${e.method} ${e.path} ${e.status}`.toLowerCase().includes(filter)) return;

  const tr = document.createElement('tr');
  if (animate) tr.className = 'new';
  tr.innerHTML = `
    <td>${e.timestamp}</td>
    <td><span class="method ${e.method}">${e.method}</span></td>
    <td><span class="path">${e.path}</span><span class="query">${e.query ? '?' + e.query : ''}</span></td>
    <td><span class="status-badge ${statusClass(e.status)}">${e.status}</span></td>
    <td><span class="duration ${durationClass(e.duration_ms)}">${e.duration_ms}ms</span></td>
    <td><span class="user-id">${e.user_id}</span></td>
    <td><span class="req-id">${e.request_id}</span></td>
  `;
  tbody.appendChild(tr);
  if (autoScroll) window.scrollTo(0, document.body.scrollHeight);
}

function clearLogs() {
  entries = [];
  tbody.innerHTML = '<tr class="empty" id="empty-row"><td colspan="7">Waiting for requests...</td></tr>';
  countEl.textContent = '0 requests';
}

function refilter() {
  tbody.innerHTML = '';
  const filter = filterInput.value.toLowerCase();
  const filtered = filter
    ? entries.filter(e => `${e.method} ${e.path} ${e.status}`.toLowerCase().includes(filter))
    : entries;
  if (filtered.length === 0) {
    tbody.innerHTML = '<tr class="empty"><td colspan="7">No matching requests</td></tr>';
    return;
  }
  filtered.forEach(e => addRow(e, false));
}

filterInput.addEventListener('input', refilter);

function toggleScroll() {
  autoScroll = !autoScroll;
  document.getElementById('scroll-btn').textContent = `Auto-scroll: ${autoScroll ? 'ON' : 'OFF'}`;
}

function connect() {
  const es = new EventSource('/dev/logs/sse');
  es.onopen = () => { dot.className = 'dot'; connStatus.textContent = 'Connected'; };
  es.onerror = () => { dot.className = 'dot disconnected'; connStatus.textContent = 'Reconnecting...'; };
  es.onmessage = (evt) => {
    const e = JSON.parse(evt.data);
    entries.push(e);
    countEl.textContent = `${entries.length} requests`;
    addRow(e, true);
  };
}

connect();
</script>
</body>
</html>
""".replace("__BRAND__", branding.APP_NAME)
