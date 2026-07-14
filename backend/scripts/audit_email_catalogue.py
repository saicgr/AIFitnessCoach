#!/usr/bin/env python3
"""
Email catalogue audit — every email type defined in code vs. what ACTUALLY sends.

Why this exists (2026-07-13):
  The backend defines ~35 email types across 15 modules. Production reality:
  **most of them have never sent a single email, ever** — the whole 6-step cancel
  ladder, every merch type, `streak_at_risk`, `comeback`, `idle_nudge`,
  `win_back_30`, `weekly_summary`. They are registered in the hourly cron, they
  cost a DB pass an hour, they carry copy nobody has read — and they are exactly
  the population the new global frequency cap (`services/email_sender.py`:
  2 per user-local day, 4 per rolling 7 days) is sized for. If several wake up at
  once, the day-3 pile-up stops being hypothetical. Nothing in the repo could
  tell you which types were live and which were dead. This does.

One row per email type:
  TRIGGER   — cron (+ the tier-registry job that fires it) / event (+ the caller
              files) / script / UNREFERENCED (a send site nothing can reach)
  TIER      — cron tier T1..T4 (send-time cap slots go to lower tiers first)
  COOLDOWN  — the per-type dedup window enforced in api/v1/email_cron.py
  CAP       — CAPPED / EXEMPT, read from services/email_sender.is_exempt()
              (that module is the single source of truth; never re-listed here)
  SENDS     — real rows in public.email_send_log (count, distinct users, last)
  VERDICT   — LIVE / DEAD (defined, never sent) / ORPHAN (sent, not in code)

Nothing is hardcoded: the catalogue is extracted with `ast` from every
`email_sender.send(..., email_type=...)` call site, resolving dynamic dispatch
(`getattr(email_svc, send_fn_name)`), f-string types (`f"cancel_offer_{days}d"`)
and pass-through params (`_dsar_send(..., email_type)`), then cross-referenced
against the cron tier registry and the send log.

Usage:
    python scripts/audit_email_catalogue.py              # full report
    python scripts/audit_email_catalogue.py --check      # exit 1 on WIRING DRIFT
    python scripts/audit_email_catalogue.py --check --fail-on-dead
                                                         # also exit 1 on dead types
    python scripts/audit_email_catalogue.py --json       # machine-readable

--check fails on WIRING DRIFT only — bugs, not judgement calls:
  * a cron job registered in the tier table whose email type resolves to nothing
    (the job runs and either sends nothing or sends an untracked type)
  * a send site whose email_type can't be resolved statically (it can be neither
    frequency-capped nor deduped, because both key on email_type)
  * a cap-key / log-key mismatch on a NON-exempt type: the job writes
    email_send_log with type A but email_sender sees type B, so the cooldown and
    the frequency cap count different things
  * a send site with no caller anywhere in the backend — dead code that can't fire
Deadness is NOT a --check failure by default: pruning a never-sent type is a
product decision. Once the catalogue has been pruned deliberately, run with
--fail-on-dead to keep it pruned.

Environment: SUPABASE_URL, SUPABASE_SERVICE_KEY (via core.supabase_client)
"""

import argparse
import ast
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, List, Set, Tuple

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

BACKEND = Path(__file__).resolve().parent.parent
CRON_REL = "api/v1/email_cron.py"
CRON_FILE = BACKEND / CRON_REL

# Scanned for send sites + callers. `tests/` is scanned for CALLERS only — a type
# that only a test fires is UNREFERENCED in product code, which is the point.
SCAN_DIRS = ("api", "services", "scripts")
CALLER_DIRS = ("api", "services", "scripts", "core", "tests")
SKIP_PARTS = {".venv", "venv", "node_modules", "__pycache__", "migrations"}

PATTERN_HOLE = "\x00"  # placeholder for an f-string interpolation
MODULE = "<module>"    # scope key for module-level assignments


def _py_files(dirs) -> List[Path]:
    out: List[Path] = []
    for d in dirs:
        root = BACKEND / d
        if not root.exists():
            continue
        out.extend(p for p in root.rglob("*.py")
                   if not any(part in SKIP_PARTS for part in p.parts))
    return sorted(out)


def _rel(p: Path) -> str:
    return str(p.relative_to(BACKEND))


def _kwarg(call: ast.Call, name: str):
    for kw in call.keywords:
        if kw.arg == name:
            return kw.value
    return None


# ─── Pass 1: index the tree (functions, call sites, send sites) ─────────────

class _Indexer(ast.NodeVisitor):
    """One pass per file: function defs, every call site's arguments, and every
    `email_sender.send(...)` with the raw AST of its email_type argument."""

    def __init__(self, path: Path, idx: "Index"):
        self.path = path
        self.idx = idx
        self.stack: List[str] = []

    def _fn(self, node):
        params = [a.arg for a in node.args.posonlyargs + node.args.args + node.args.kwonlyargs]
        self.idx.func_params[node.name] = params
        self.idx.func_file[node.name] = _rel(self.path)
        self.idx.func_line[node.name] = node.lineno
        self.stack.append(node.name)
        self.generic_visit(node)
        self.stack.pop()

    visit_FunctionDef = _fn
    visit_AsyncFunctionDef = _fn

    def visit_Assign(self, node):
        if len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
            scope = self.stack[-1] if self.stack else MODULE
            self.idx.assigns[scope][node.targets[0].id].append(node.value)
        self.generic_visit(node)

    def visit_Call(self, node):
        callee = None
        if isinstance(node.func, ast.Name):
            callee = node.func.id
        elif isinstance(node.func, ast.Attribute):
            callee = node.func.attr
        if callee:
            self.idx.callsites[callee].append(node)
            if self.stack:
                self.idx.calls[self.stack[-1]].add(callee)
                # Dynamic dispatch: `send_fn_name="send_grace_period"` + getattr.
                # The string literal IS the call edge — without this the whole
                # cancel ladder looks unreachable.
                for kw in node.keywords:
                    if kw.arg and kw.arg.endswith("fn_name") and isinstance(kw.value, ast.Constant) \
                            and isinstance(kw.value.value, str):
                        self.idx.calls[self.stack[-1]].add(kw.value.value)

        if _is_send(node.func):
            self.idx.send_sites.append({
                "file": _rel(self.path),
                "line": node.lineno,
                "func": self.stack[-1] if self.stack else "<module>",
                "node": _kwarg(node, "email_type"),
                "has_user_id": _kwarg(node, "user_id") is not None,
            })
        self.generic_visit(node)

    def visit_Dict(self, node):
        # An `email_send_log` row built as a dict literal — this is how the two
        # event-side loggers (trophy_triggers, crud_completion) record a send.
        # A type with NO such write path is INVISIBLE to email_send_log, so a
        # zero send count proves nothing about it (see UNLOGGED in the report).
        if self.idx.file_logs_sends.get(_rel(self.path)):
            for k, v in zip(node.keys, node.values):
                if isinstance(k, ast.Constant) and k.value == "email_type" \
                        and isinstance(v, ast.Constant) and isinstance(v.value, str):
                    self.idx.logged_types.add(v.value)
        self.generic_visit(node)


def _is_send(func) -> bool:
    """`email_sender.send(...)` / `services.email_sender.send(...)`."""
    if not isinstance(func, ast.Attribute) or func.attr != "send":
        return False
    v = func.value
    if isinstance(v, ast.Name):
        return v.id == "email_sender"
    if isinstance(v, ast.Attribute):
        return v.attr == "email_sender"
    return False


class Index:
    def __init__(self):
        self.func_params: Dict[str, List[str]] = {}
        self.func_file: Dict[str, str] = {}
        self.func_line: Dict[str, int] = {}
        self.assigns: Dict[str, Dict[str, List[ast.AST]]] = defaultdict(lambda: defaultdict(list))
        self.callsites: Dict[str, List[ast.Call]] = defaultdict(list)
        self.calls: Dict[str, Set[str]] = defaultdict(set)
        self.send_sites: List[Dict[str, Any]] = []
        self.logged_types: Set[str] = set()
        self.file_logs_sends: Dict[str, bool] = {}

    @classmethod
    def build(cls) -> "Index":
        idx = cls()
        for p in _py_files(SCAN_DIRS):
            try:
                src = p.read_text()
                tree = ast.parse(src, filename=str(p))
            except SyntaxError as e:
                print(f"⚠️  parse failed: {_rel(p)}: {e}", file=sys.stderr)
                continue
            idx.file_logs_sends[_rel(p)] = 'table("email_send_log")' in src and ".insert(" in src
            _Indexer(p, idx).visit(tree)
        return idx

    # ── static resolution of an email_type expression ──
    def resolve(self, node, func: str, depth: int = 0) -> Tuple[Set[str], Set[str]]:
        """(literal types, pattern types). A pattern is an f-string with its holes
        replaced by PATTERN_HOLE — expanded later against the known type universe."""
        if node is None or depth > 6:
            return set(), set()
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            return {node.value}, set()
        if isinstance(node, ast.JoinedStr):
            parts = []
            for v in node.values:
                if isinstance(v, ast.Constant) and isinstance(v.value, str):
                    parts.append(v.value)
                else:
                    parts.append(PATTERN_HOLE)
            return set(), {"".join(parts)}
        if isinstance(node, ast.BoolOp) and isinstance(node.op, ast.Or):
            lits, pats = set(), set()
            for v in node.values:
                a, b = self.resolve(v, func, depth + 1)
                lits |= a
                pats |= b
            return lits, pats
        if isinstance(node, ast.IfExp):
            a1, b1 = self.resolve(node.body, func, depth + 1)
            a2, b2 = self.resolve(node.orelse, func, depth + 1)
            return a1 | a2, b1 | b2
        if isinstance(node, ast.Name):
            lits, pats = set(), set()
            for assigned in (self.assigns[func].get(node.id, [])
                             + self.assigns[MODULE].get(node.id, [])):
                a, b = self.resolve(assigned, func, depth + 1)
                lits |= a
                pats |= b
            if node.id in self.func_params.get(func, []):
                a, b = self._from_callers(func, node.id, depth)
                lits |= a
                pats |= b
            return lits, pats
        # `day_to_type.get(day)` / `day_to_type[day]` on a dict literal: the key is
        # dynamic, so every value the table can yield is a candidate type.
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) \
                and node.func.attr == "get" and isinstance(node.func.value, ast.Name):
            return self._dict_values(node.func.value.id, func), set()
        if isinstance(node, ast.Subscript) and isinstance(node.value, ast.Name):
            return self._dict_values(node.value.id, func), set()
        return set(), set()

    def _dict_values(self, name: str, func: str) -> Set[str]:
        out: Set[str] = set()
        for assigned in self.assigns[func].get(name, []) + self.assigns[MODULE].get(name, []):
            if isinstance(assigned, ast.Dict):
                out |= {v.value for v in assigned.values
                        if isinstance(v, ast.Constant) and isinstance(v.value, str)}
        return out

    def _from_callers(self, func: str, param: str, depth: int) -> Tuple[Set[str], Set[str]]:
        """Pass-through param: take the literal(s) the CALLERS supply for it."""
        params = self.func_params.get(func, [])
        if param not in params:
            return set(), set()
        pos = params.index(param)
        lits, pats = set(), set()
        for call in self.callsites.get(func, []):
            arg = _kwarg(call, param)
            if arg is None:
                # positional — account for `self` on methods (callsite drops it)
                for offset in ({pos, pos - 1} if params and params[0] == "self" else {pos}):
                    if 0 <= offset < len(call.args):
                        arg = call.args[offset]
                        break
            if arg is None:
                continue
            a, b = self.resolve(arg, func, depth + 1)
            lits |= a
            pats |= b
        return lits, pats


# ─── Pass 2: the cron tier registry + cooldowns ─────────────────────────────

def parse_cron(idx: Index) -> Dict[str, Any]:
    """registry: job -> {tier, func, log_type, cooldowns}. `log_type` is the
    email_type the job writes to email_send_log (the DEDUP key), which is not
    necessarily the type email_sender sees (the CAP key) — a mismatch is drift."""
    tree = ast.parse(CRON_FILE.read_text(), filename=str(CRON_FILE))

    default_cd = 7
    for n in ast.walk(tree):
        if isinstance(n, ast.Assign) and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name) \
                and n.targets[0].id == "DEFAULT_COOLDOWN_DAYS" and isinstance(n.value, ast.Constant):
            default_cd = n.value.value

    registry: Dict[str, Dict[str, Any]] = {}
    for n in ast.walk(tree):
        tgt = None
        if isinstance(n, ast.AnnAssign) and isinstance(n.target, ast.Name):
            tgt = n.target.id
        elif isinstance(n, ast.Assign) and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name):
            tgt = n.targets[0].id
        if tgt != "tiers" or not isinstance(n.value, ast.List):
            continue
        for tier_i, tier in enumerate(n.value.elts, start=1):
            if not isinstance(tier, ast.List):
                continue
            for e in tier.elts:
                if not (isinstance(e, ast.Tuple) and len(e.elts) == 2):
                    continue
                name_n, call_n = e.elts
                if not (isinstance(name_n, ast.Constant) and isinstance(name_n.value, str)):
                    continue
                fn = call_n.func.id if isinstance(call_n, ast.Call) and isinstance(call_n.func, ast.Name) else None
                registry[name_n.value] = {"tier": tier_i, "func": fn}

    # cooldowns + the logged type, per email_cron function
    cooldowns: Dict[str, Set[int]] = defaultdict(set)
    log_types: Dict[str, Set[str]] = defaultdict(set)
    stack: List[str] = []

    class _W(ast.NodeVisitor):
        def _fn(self, node):
            stack.append(node.name)
            self.generic_visit(node)
            stack.pop()

        visit_FunctionDef = _fn
        visit_AsyncFunctionDef = _fn

        def visit_Call(self, node):
            if stack:
                cur = stack[-1]
                name = node.func.id if isinstance(node.func, ast.Name) else (
                    node.func.attr if isinstance(node.func, ast.Attribute) else None)
                if name == "_was_recently_sent":
                    cd = _kwarg(node, "cooldown_days")
                    if isinstance(cd, ast.Constant) and isinstance(cd.value, int):
                        cooldowns[cur].add(cd.value)
                    elif cd is None:
                        cooldowns[cur].add(default_cd)
                    if len(node.args) >= 3:
                        lits, pats = idx.resolve(node.args[2], cur)
                        log_types[cur] |= lits | pats
                elif name == "_log_email_sent" and len(node.args) >= 3:
                    lits, pats = idx.resolve(node.args[2], cur)
                    log_types[cur] |= lits | pats
                elif name == "_run_cancel_job":
                    cd = _kwarg(node, "cooldown")
                    if isinstance(cd, ast.Constant) and isinstance(cd.value, int):
                        cooldowns[cur].add(cd.value)
                    if len(node.args) >= 3:
                        lits, pats = idx.resolve(node.args[2], cur)
                        log_types[cur] |= lits | pats
            self.generic_visit(node)

    _W().visit(tree)
    return {"registry": registry, "cooldowns": cooldowns, "log_types": log_types}


def _reachable(root: str, calls: Dict[str, Set[str]]) -> Set[str]:
    seen, stack = {root}, [root]
    while stack:
        for nxt in calls.get(stack.pop(), ()):
            if nxt not in seen:
                seen.add(nxt)
                stack.append(nxt)
    return seen


# ─── Pass 3: who references each send function ─────────────────────────────

def find_refs(names: Set[str]) -> Dict[str, Set[str]]:
    """name -> files that REFERENCE it: a call `f(`, a bare value `add_task(f,`,
    or a dynamic-dispatch string `send_fn_name="f"`. The defining `def` line is
    not a reference; other lines in the defining file are."""
    if not names:
        return {}
    pat = re.compile(r"(?<![\w])(" + "|".join(map(re.escape, sorted(names))) + r")(?![\w])")
    quoted = re.compile(r"\"[^\"]*\"|'[^']*'")
    refs: Dict[str, Set[str]] = defaultdict(set)
    for p in _py_files(CALLER_DIRS):
        rel = _rel(p)
        in_doc = False
        for line in p.read_text().splitlines():
            s = line.strip()
            # Docstrings mention send functions in prose ("hands the result to
            # send_weekly_summary") — that is not a call site.
            fences = s.count('"""') + s.count("'''")
            if in_doc:
                if fences:
                    in_doc = False
                continue
            if fences % 2 == 1:
                in_doc = True
                continue
            if s.startswith("#") or re.match(r"^(async\s+)?def\s+\w+\s*\(", s):
                continue
            # A function name inside a string is only a real reference when it is
            # dynamic dispatch (`send_fn_name="send_grace_period"` + getattr).
            # Otherwise it's a docstring or a log message — strip strings first,
            # or every `logger.error(f"send_week1_day1 failed")` becomes a caller.
            if "fn_name" not in s and "getattr" not in s:
                s = quoted.sub("", s)
            for m in pat.finditer(s):
                refs[m.group(1)].add(rel)
    return refs


# ─── Reality: public.email_send_log ─────────────────────────────────────────

def load_send_log() -> Tuple[Dict[str, Dict[str, Any]], int]:
    from core.supabase_client import get_supabase  # noqa: E402
    sb = get_supabase().client
    rows: List[Dict[str, Any]] = []
    page, size = 0, 1000
    while True:
        res = sb.table("email_send_log").select("email_type, user_id, sent_at") \
            .range(page * size, page * size + size - 1).execute()
        batch = res.data or []
        rows.extend(batch)
        if len(batch) < size:
            break
        page += 1

    agg: Dict[str, Dict[str, Any]] = {}
    for r in rows:
        a = agg.setdefault(r.get("email_type") or "<null>", {"sends": 0, "users": set(), "last": None})
        a["sends"] += 1
        a["users"].add(r.get("user_id"))
        ts = (r.get("sent_at") or "")[:10]
        if ts and (a["last"] is None or ts > a["last"]):
            a["last"] = ts
    for a in agg.values():
        a["users"] = len(a["users"])
    return agg, len(rows)


# ─── Build ─────────────────────────────────────────────────────────────────

def build(log: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
    import services.email_sender as email_sender  # noqa: E402

    idx = Index.build()
    cron = parse_cron(idx)
    registry, cooldowns, cron_log_types = cron["registry"], cron["cooldowns"], cron["log_types"]

    # Universe of concrete type names an f-string pattern may expand into.
    universe: Set[str] = set(log) | set(registry)
    for f in cron_log_types.values():
        universe |= {t for t in f if PATTERN_HOLE not in t}

    def expand(pats: Set[str]) -> Set[str]:
        out: Set[str] = set()
        for p in pats:
            rx = re.compile("^" + ".+".join(re.escape(x) for x in p.split(PATTERN_HOLE)) + "$")
            out |= {t for t in universe if rx.match(t)}
        return out

    # send-site func -> types it hands to email_sender (the CAP key)
    func_types: Dict[str, Set[str]] = defaultdict(set)
    type_sites: Dict[str, List[str]] = defaultdict(list)
    unresolved: List[Dict[str, Any]] = []
    for s in idx.send_sites:
        lits, pats = idx.resolve(s["node"], s["func"])
        types = lits | expand(pats)
        if not types:
            unresolved.append({"file": s["file"], "line": s["line"], "func": s["func"]})
            continue
        for t in types:
            func_types[s["func"]].add(t)
            type_sites[t].append(f"{s['file']}:{s['line']}")

    # cron job -> types (cap key) + logged type (dedup key) + cooldowns
    type_jobs: Dict[str, List[str]] = defaultdict(list)
    for job, meta in registry.items():
        reach = _reachable(meta["func"], idx.calls) if meta["func"] else set()
        cap_types: Set[str] = set()
        log_types: Set[str] = set()
        cds: Set[int] = set()
        for name in reach:
            cap_types |= func_types.get(name, set())
            cds |= cooldowns.get(name, set())
            lt = cron_log_types.get(name, set())
            log_types |= {t for t in lt if PATTERN_HOLE not in t} | expand({t for t in lt if PATTERN_HOLE in t})
        meta["cap_types"] = sorted(cap_types)
        meta["log_types"] = sorted(log_types)
        meta["cooldowns"] = sorted(cds)
        for t in cap_types | log_types:
            type_jobs[t].append(job)

    refs = find_refs(set(func_types))

    # Types the send log can even SEE: the cron logger + the two event-side
    # `email_send_log` inserts. A type with no write path is invisible to the
    # log, so `sends == 0` is not evidence of deadness for it.
    logged_types: Set[str] = set(idx.logged_types)
    for m in registry.values():
        logged_types |= set(m["log_types"])

    all_types = set(type_sites) | set(t for t in log) | {
        t for m in registry.values() for t in m["log_types"]}

    # Drop shadowed aliases: `week1_day3` is a value in the job's `day_to_type`
    # lookup, but day 3 always narrows to week1_day3_completed / _stalled before
    # anything is sent or logged. It has no send site and no log row, and a more
    # specific type from the same job does — so it is a base name, not a live type.
    # Reporting it as DEAD would invite someone to "prune" a table entry the job
    # still reads.
    shadowed = {
        t for t in all_types
        if t not in type_sites and not log.get(t)
        and any(o != t and o.startswith(t + "_") and (o in type_sites or o in log)
                and set(type_jobs.get(o, [])) & set(type_jobs.get(t, []))
                for o in all_types)
    }
    all_types -= shadowed

    rows: List[Dict[str, Any]] = []
    for t in sorted(all_types):
        sites = type_sites.get(t, [])
        jobs = sorted(set(type_jobs.get(t, [])))
        # The cron call graph smears shared helpers (`_run_cancel_job`,
        # `_job_week1_email`) across every job that calls them. Anchor on the
        # registry name when it identifies the job unambiguously.
        exact = [j for j in jobs if j == t]
        if exact:
            jobs = exact
        elif len(jobs) > 1:
            prefixed = [j for j in jobs if t.startswith(j)]
            if prefixed:
                jobs = [max(prefixed, key=len)]
        tier = min((registry[j]["tier"] for j in jobs), default=None)
        cds: Set[int] = set()
        for j in jobs:
            cds |= set(registry[j]["cooldowns"])

        callers: Set[str] = set()
        for s in sites:
            fn = next((x["func"] for x in idx.send_sites
                       if f"{x['file']}:{x['line']}" == s), None)
            callers |= {f for f in refs.get(fn, set()) if f != CRON_REL}
        ext = sorted(f for f in callers if not f.startswith(("scripts/", "tests/")))
        scr = sorted(f for f in callers if f.startswith("scripts/"))

        if jobs:
            # a type can be BOTH cron-fired and event-fired (`verification` is sent
            # at signup AND by the reminder job) — show both.
            trigger, evidence = "cron", jobs + [f"+{e}" for e in ext]
        elif ext:
            trigger, evidence = "event", ext
        elif scr:
            trigger, evidence = "script", scr
        elif sites:
            trigger, evidence = "UNREFERENCED", []
        else:
            trigger, evidence = "log-only", []

        sends = log.get(t, {}).get("sends", 0)
        in_code = bool(sites) or bool(jobs)
        logged = t in logged_types
        if not in_code:
            verdict = "ORPHAN"
        elif sends:
            verdict = "LIVE"
        elif not logged:
            verdict = "UNLOGGED"   # no email_send_log write path — 0 proves nothing
        else:
            verdict = "DEAD"       # logged type, zero rows → provably never sent
        rows.append({
            "type": t,
            "in_code": in_code,
            "trigger": trigger,
            "evidence": evidence,
            "jobs": jobs,
            "tier": tier,
            "cooldown_days": sorted(cds),
            "sites": sites,
            "logged": logged,
            "capped": not email_sender.is_exempt(t),
            "sends": sends,
            "users": log.get(t, {}).get("users", 0),
            "last_sent": log.get(t, {}).get("last"),
            "verdict": verdict,
        })

    # cap-key vs dedup-key mismatch (the cron logs A, email_sender sees B)
    key_mismatch = []
    for job, m in registry.items():
        if not m["cap_types"] and not m["log_types"]:
            continue
        extra_log = set(m["log_types"]) - set(m["cap_types"])
        extra_cap = set(m["cap_types"]) - set(m["log_types"])
        if extra_log and extra_cap:
            both_exempt = all(email_sender.is_exempt(x) for x in extra_log | extra_cap)
            key_mismatch.append({"job": job, "logged": sorted(extra_log),
                                 "sent_as": sorted(extra_cap), "both_exempt": both_exempt})

    unresolved_jobs = sorted(j for j, m in registry.items()
                             if not m["cap_types"] and not m["log_types"])
    return {"rows": rows, "registry": registry, "unresolved_sites": unresolved,
            "unresolved_jobs": unresolved_jobs, "key_mismatch": key_mismatch}


# ─── Report ────────────────────────────────────────────────────────────────

def report(res: Dict[str, Any], total_rows: int) -> int:
    rows = res["rows"]
    live = [r for r in rows if r["verdict"] == "LIVE"]
    dead = [r for r in rows if r["verdict"] == "DEAD"]
    unlogged = [r for r in rows if r["verdict"] == "UNLOGGED"]
    orphan = [r for r in rows if r["verdict"] == "ORPHAN"]
    in_code = [r for r in rows if r["in_code"]]

    print("=" * 100)
    print("EMAIL CATALOGUE AUDIT")
    print("=" * 100)
    print(f"{len(in_code)} email types in code · {len(live)} have EVER sent · {len(dead)} DEAD "
          f"(logged type, zero rows → provably never sent) · {len(unlogged)} UNLOGGED (no "
          f"email_send_log write path — the log cannot see them) · {len(orphan)} ORPHAN "
          f"(in the log, no longer in code)")
    print(f"public.email_send_log: {total_rows} rows")
    print()

    hdr = (f"   {'TYPE':<28} {'TRIGGER':<32} {'TIER':<5} {'COOLDOWN':<9} "
           f"{'CAP':<7} {'LOGGED':<7} {'SENDS':>5} {'USERS':>5}  {'LAST SENT'}")
    print(hdr)
    print("-" * 116)
    for r in rows:
        ev = ",".join(r["evidence"][:2]) if r["evidence"] else ""
        if r["trigger"] in ("event", "script"):
            ev = ",".join(e.split("/")[-1] for e in r["evidence"][:2])
        if len(r["evidence"]) > 2:
            ev += f"+{len(r['evidence']) - 2}"
        trig = f"{r['trigger']}:{ev}" if ev else r["trigger"]
        mark = {"LIVE": "✅", "DEAD": "💀", "UNLOGGED": "❔", "ORPHAN": "🗑️"}[r["verdict"]]
        cd = "/".join(f"{c}d" for c in r["cooldown_days"]) or "—"
        print(f"{mark}  {r['type']:<28} {trig[:32]:<32} "
              f"{('T' + str(r['tier'])) if r['tier'] else '—':<5} {cd:<9} "
              f"{'CAPPED' if r['capped'] else 'EXEMPT':<7} {'yes' if r['logged'] else 'NO':<7} "
              f"{r['sends']:>5} {r['users']:>5}  {r['last_sent'] or 'never'}")

    if dead:
        print()
        print(f"💀 DEAD — {len(dead)} type(s) that write an email_send_log row when they fire and "
              f"have ZERO rows. These have provably never sent. Prune or wire up:")
        for r in dead:
            print(f"     {r['type']:<28} {r['trigger']}: {', '.join(r['evidence']) or '—'}")

    if unlogged:
        print()
        print(f"❔ UNLOGGED — {len(unlogged)} type(s) with NO email_send_log write path. Zero sends "
              f"here is not evidence of deadness; it is evidence of blindness — nothing records "
              f"them, so the cooldown and the cross-run frequency-cap ledger cannot see them "
              f"either:")
        capped_unlogged = [r for r in unlogged if r["capped"]]
        for r in unlogged:
            flag = "  ← CAPPED but unlogged" if r["capped"] else ""
            print(f"     {r['type']:<28} {r['trigger']}: {', '.join(r['evidence']) or '—'}{flag}")
        if capped_unlogged:
            n = len(capped_unlogged)
            print(f"     ⚠️  {n} of these {'is' if n == 1 else 'are'} CAPPED: email_sender counts "
                  f"{'it' if n == 1 else 'them'} in-process, but no row is persisted, so a later "
                  f"cron run re-seeds its ledger without {'it' if n == 1 else 'them'} and can "
                  f"over-send.")

    if orphan:
        print()
        print(f"🗑️  ORPHAN — {len(orphan)} type(s) in email_send_log with no send site (retired):")
        for r in orphan:
            print(f"     {r['type']:<28} {r['sends']} send(s), last {r['last_sent']}")

    problems: List[str] = []
    for j in res["unresolved_jobs"]:
        problems.append(f"cron job '{j}' is registered in the tier table but no email_type "
                        f"resolves from its call graph — it sends an untracked type or nothing")
    for s in res["unresolved_sites"]:
        problems.append(f"{s['file']}:{s['line']} ({s['func']}) — email_sender.send with a "
                        f"non-static email_type: it can be neither capped nor deduped")
    for m in res["key_mismatch"]:
        if not m["both_exempt"]:
            problems.append(f"cron job '{m['job']}' logs {m['logged']} but email_sender sees "
                            f"{m['sent_as']} — the cooldown and the frequency cap key on "
                            f"different types")
    for r in rows:
        if r["trigger"] == "UNREFERENCED":
            problems.append(f"'{r['type']}' has a send site ({', '.join(r['sites'])}) with NO "
                            f"reference anywhere in the backend — it can never fire")

    notes = [m for m in res["key_mismatch"] if m["both_exempt"]]
    if notes:
        print()
        print("ℹ️  cap-key / log-key mismatches on EXEMPT types (harmless today — the cap ignores "
              "both sides — but they will bite the day either type stops being exempt):")
        for m in notes:
            print(f"     {m['job']}: logs {m['logged']}, email_sender sees {m['sent_as']}")

    print()
    if problems:
        print(f"❌ {len(problems)} wiring problem(s):")
        for p in problems:
            print(f"     • {p}")
    else:
        print("✅ no wiring drift — every cron job resolves to an email type, every send site has "
              "a static email_type, every type has a caller")
    return len(problems)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="exit 1 on wiring drift")
    ap.add_argument("--fail-on-dead", action="store_true",
                    help="with --check, also exit 1 on any never-sent (DEAD) type")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    args = ap.parse_args()

    try:
        log, total_rows = load_send_log()
    except Exception as e:
        print(f"❌ cannot read public.email_send_log: {e}", file=sys.stderr)
        print("   needs SUPABASE_URL + SUPABASE_SERVICE_KEY — this audit reports REAL sends, so "
              "it never guesses.", file=sys.stderr)
        sys.exit(2)

    res = build(log)

    if args.json:
        print(json.dumps({"total_log_rows": total_rows, **res}, indent=2, default=str))
        n = (len(res["unresolved_jobs"]) + len(res["unresolved_sites"])
             + sum(1 for m in res["key_mismatch"] if not m["both_exempt"])
             + sum(1 for r in res["rows"] if r["trigger"] == "UNREFERENCED"))
    else:
        n = report(res, total_rows)

    if args.check:
        if n:
            sys.exit(1)
        dead = [r for r in res["rows"] if r["verdict"] == "DEAD"]
        if args.fail_on_dead and dead:
            print(f"❌ --fail-on-dead: {len(dead)} dead email type(s)")
            sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
