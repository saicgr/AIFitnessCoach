#!/usr/bin/env python3
"""
Exercise-image backfill pipeline.

For each exercise with no image (from the saved DB query), one-by-one:
  1. GENERATE a render with gemini-3.1-flash-image (fixed style block + per-exercise pose block)
  2. VALIDATE it with gemini-3.1-flash vision QA against the style checklist
  3. If it fails a hard criterion -> regenerate (up to MAX_ATTEMPTS)
  4. Mark the row in missing_images_tracker.md AFTER validation (Image Generated + Validation cols)

Resumable: rows already marked done (✅) in the tracker are skipped.
S3 upload is a SEPARATE later step (left ⬜ Pending here).

Usage:
  python run_pipeline.py            # process all pending
  python run_pipeline.py --limit 1  # process just the next N pending
"""
import os, sys, json, base64, re, time, glob, signal, urllib.request, urllib.error
import brand_stamp

BASE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(BASE, "..", "..", ".."))
ENV  = os.path.join(ROOT, "backend", ".env")
DATA = "/Users/saichetangrandhe/.claude/projects/-Users-saichetangrandhe-AIFitnessCoach/e5e4018d-25d8-49c1-befc-ef752fb3086b/tool-results/mcp-plugin_supabase_supabase-execute_sql-1782161767000.txt"
TRACKER = os.path.join(BASE, "missing_images_tracker.md")
GENDIR  = os.path.join(BASE, "generated")
GEN_MODEL = "gemini-3.1-flash-image"
VAL_MODEL = "gemini-3.5-flash"
MAX_ATTEMPTS = 3
os.makedirs(GENDIR, exist_ok=True)

def api_key():
    for line in open(ENV):
        if line.startswith("GEMINI_API_KEY="):
            return line.split("=", 1)[1].strip().strip('"').strip("'")
    raise SystemExit("no GEMINI_API_KEY")
KEY = api_key()

ASPECT = "3:4"   # vertical portrait for mobile
STYLE = """Photoreal 3D anatomical exercise illustration in a clean medical / fitness-app style.
- VERTICAL PORTRAIT composition framed for a mobile phone screen.
- Pure solid white background (#FFFFFF): no gradient, floor, border, vignette, or shadow on the backdrop.
- A SINGLE anatomical ecorche figure: skin removed, full detailed musculature visible (myology model), androgynous athletic build, anatomically correct with exactly two arms and two legs.
- CRITICAL COLORING RULE: the figure's musculature is OVERWHELMINGLY neutral medium gray. ONLY the small specific target muscle group for this exercise is colored deep anatomical red/maroon. The vast majority of the body stays gray. Do NOT paint the torso, arms, legs, or whole body red. If unsure, color LESS red, not more.
- Non-targeted muscles rendered neutral medium gray.
- Equipment (if any) in dark charcoal-gray matte metal (hexagonal dumbbell ends, knurled bars, plates). Dark gray athletic shoes with white soles.
- MOTION ARROWS WITH LABELS: there must be PRECISELY TWO arrows in the entire image -- count them: exactly one arrow labeled "1." and exactly one arrow labeled "2.". NO third arrow, NO fourth arrow, NO extra arrow, NO unlabeled arrow anywhere (not near the hands, feet, or background). The two labels must be different and numbered 1 and 2 (never two arrows sharing a number). Each arrow is a clean, smooth, CURVED bright blue (#1E6BE6) line tracing the path the body/limbs travel. Label each in LARGE, BOLD, clearly legible blue text, e.g. "1. Lower down", "2. Drive up", using the correct phases for THIS exercise, 2 to 4 words, correctly spelled, no typos. If you are tempted to add a third arrow, DO NOT -- keep it to exactly two.
- Soft even studio lighting, subtle ambient-occlusion contact shadow, matte finish, subject centered, whole figure in frame with margin.
- Apart from the short numbered arrow labels, NO other text, watermark, logo, or grid lines."""

def slug(n): return re.sub(r"[^a-z0-9]+", "_", n.lower().strip()).strip("_")

def clean_target(t):
    """Verbose 'Quadriceps (Quadriceps Femoris), Hamstrings (...), Glutes' -> 'Quadriceps, Hamstrings, Glutes'."""
    if not t: return "the primary working muscle"
    groups = [re.sub(r"\s*\(.*?\)", "", g).strip() for g in t.split(",")]
    seen, out = set(), []
    for g in groups:
        gl = g.lower()
        if g and gl not in seen:
            seen.add(gl); out.append(g)
    return ", ".join(out[:3]) if out else "the primary working muscle"

def primary_target(t):
    return clean_target(t).split(",")[0].strip()

def load_rows():
    raw = open(DATA).read()
    chunk = raw[raw.find('['):raw.rfind(']')+1].replace('\\"', '"').replace('\\\\', '\\')
    return json.loads(chunk)

def post(model, body):
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={KEY}"
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    for attempt in range(4):
        try:
            r = urllib.request.urlopen(req, timeout=180)
            return json.loads(r.read())
        except urllib.error.HTTPError as e:
            msg = e.read().decode()[:200]
            if e.code in (429, 500, 503) and attempt < 3:
                time.sleep(5 * (attempt + 1)); continue
            raise RuntimeError(f"HTTP {e.code}: {msg}")
        except Exception as e:
            if attempt < 3:
                time.sleep(5); continue
            raise
    raise RuntimeError("unreachable")

COST = {"gen": 0.0, "val": 0.0}

def _load_overrides():
    p = os.path.join(BASE, "overrides.json")
    if os.path.exists(p):
        return {k.strip().lower(): v for k, v in json.load(open(p)).items()}
    return {}
OVERRIDES = _load_overrides()

# ---- Per-type style support (candidate mode) -----------------------------
# Each row may carry a "style" in {dynamic, static, smr, cars}. We load the
# matching style_prompt_<style>.txt; fall back to the inline dynamic STYLE.
_STYLE_CACHE = {}
def load_style(style_name):
    style_name = (style_name or "dynamic").strip().lower()
    if style_name in _STYLE_CACHE:
        return _STYLE_CACHE[style_name]
    p = os.path.join(BASE, f"style_prompt_{style_name}.txt")
    txt = open(p).read().strip() if os.path.exists(p) else STYLE
    _STYLE_CACHE[style_name] = txt
    return txt

def load_candidates(path):
    """Candidate JSON: [{name,type,equipment,target_muscle,style,slug,...}]."""
    rows = json.load(open(path))
    for r in rows:
        r.setdefault("body_part", r.get("target_muscle", ""))
    return rows

def pose_desc(r):
    """Ask a text model that knows exercise form for the correct pose + the ONE muscle to highlight.
    Fixes wrong-pose and whole-body-red failures. Falls back to DB target on any error.
    Per-exercise OVERRIDES (overrides.json) can force muscle / pose / equipment / add emphasis."""
    name = r["name"]; eq = (r.get("equipment", "") or "").strip() or "bodyweight"
    q = (f"You are a certified strength & conditioning coach. For the exercise \"{name}\" (equipment: {eq}), "
         "describe the SINGLE most recognizable position to illustrate it so an artist draws it correctly. "
         "Return ONLY JSON: {\"pose\":\"2-3 precise sentences: body orientation, what the limbs/torso do, "
         "grip, and the best camera angle to show it\", \"primary_muscle\":\"the ONE primary muscle group to "
         "highlight in red\"}. Be anatomically correct.")
    result = {"pose": "", "primary_muscle": clean_target(r.get("target_muscle", ""))}
    try:
        d = post(VAL_MODEL, {"contents": [{"parts": [{"text": q}]}],
                             "generationConfig": {"responseModalities": ["TEXT"], "responseMimeType": "application/json"}})
        um = d.get("usageMetadata", {})
        COST["val"] += um.get("promptTokenCount", 0) * 0.10e-6 + um.get("candidatesTokenCount", 0) * 0.40e-6
        t = "".join(p.get("text", "") for c in d.get("candidates", []) for p in c.get("content", {}).get("parts", []))
        j = json.loads(t[t.find("{"):t.rfind("}") + 1])
        if j.get("pose") and j.get("primary_muscle"):
            result = j
    except Exception:
        pass
    ov = OVERRIDES.get(name.strip().lower())
    if ov:
        if ov.get("muscle"):    result["primary_muscle"] = ov["muscle"]
        if ov.get("pose"):      result["pose"] = ov["pose"]
        result["emphasis"]    = ov.get("emphasis", "")
        result["eq_override"] = ov.get("equipment")
    return result

def exercise_block(r, pd):
    name = r["name"]
    eq = pd.get("eq_override") or (r.get("equipment", "") or "").strip()
    primary = pd.get("primary_muscle") or clean_target(r.get("target_muscle", ""))
    eq_line = ("Equipment: none - bodyweight only, no equipment in frame."
               if (not eq or eq.lower() == "bodyweight")
               else f"Equipment used (render it in charcoal-gray): {eq}.")
    pose_line = (f"EXACT POSE TO DRAW: {pd['pose']}\n" if pd.get("pose")
                 else f"Show the figure performing \"{name}\" in correct, recognizable form at the most identifiable position.\n")
    emphasis = f"CRITICAL: {pd['emphasis']}\n" if pd.get("emphasis") else ""
    style = load_style(r.get("style", "dynamic"))
    return (f"{style}\n\nEXERCISE: {name}\n{eq_line}\n{pose_line}{emphasis}"
            f"Highlight ONLY this muscle in deep anatomical red: {primary}. Everything except that stays neutral gray.")

def generate(r, path, pd):
    data = post(GEN_MODEL, {
        "contents": [{"parts": [{"text": exercise_block(r, pd)}]}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": ASPECT}},
    })
    um = data.get("usageMetadata", {})
    img_tok = sum(d.get("tokenCount", 0) for d in um.get("candidatesTokensDetails", []) if d.get("modality") == "IMAGE")
    txt_in = um.get("promptTokenCount", 0)
    COST["gen"] += img_tok * 60e-6 + txt_in * 0.25e-6
    for cand in data.get("candidates", []):
        for p in cand.get("content", {}).get("parts", []):
            if "inlineData" in p:
                open(path, "wb").write(base64.b64decode(p["inlineData"]["data"]))
                return True
    return False

HARD = ["white_background", "single_plausible_anatomical_figure", "only_target_is_red",
        "correct_target_muscle_highlighted_red", "correct_equipment_present",
        "has_labeled_arrows", "every_arrow_labeled", "labels_legible_correct", "no_stray_text"]

def validate(r, path, pd):
    img_b64 = base64.b64encode(open(path, "rb").read()).decode()
    primary = pd.get("primary_muscle") or primary_target(r.get("target_muscle", "")); eq = (r.get("equipment", "") or "").strip() or "bodyweight (none)"
    style = (r.get("style") or "dynamic").strip().lower()
    dynamic = style == "dynamic"
    q = (f"You are a QA reviewer for anatomical exercise illustrations. "
         f"The image should depict the exercise \"{r['name']}\".\n"
         f"Primary muscle that MUST be highlighted red: {primary}\n"
         f"Expected equipment: {eq}\n\n"
         "Judge the image and return ONLY JSON with these boolean fields and a short notes string:\n"
         "{\n"
         '  "white_background": bool,            // solid white, no clutter/floor/border\n'
         '  "single_plausible_anatomical_figure": bool,  // one ecorche figure, skin off, NO extra/missing/deformed limbs\n'
         '  "only_target_is_red": bool,          // figure is PREDOMINANTLY gray and ONLY the target region is red. FALSE if most of the body / torso / whole figure is red.\n'
         '  "correct_target_muscle_highlighted_red": bool, // RED covers the primary muscle above and does NOT paint a clearly unrelated/wrong muscle red. Including a couple of extra synergist muscles is fine; true as long as the primary region is red and nothing wildly wrong is red.\n'
         '  "correct_equipment_present": bool,   // expected equipment shown (true if bodyweight & none shown)\n'
         '  "has_labeled_arrows": bool,          // >=1 blue curved motion arrow, each WITH a short numbered text label (e.g. "1. Lower down")\n'
         '  "every_arrow_labeled": bool,         // EXACTLY 2 arrows, each has its own label numbered 1 and 2. FALSE if there is any unlabeled/extra/third arrow OR two arrows share the same number\n'
         '  "labels_legible_correct": bool,      // the arrow labels are correctly-spelled real English, NOT garbled/warped/misspelled/nonsense, and describe this movement\n'
         '  "no_stray_text": bool,               // no text anywhere EXCEPT the short numbered arrow labels; no watermark/logo/grid\n'
         '  "pose_matches_exercise": bool,       // body position is recognizably this exercise\n'
         '  "notes": "one short sentence on any problem"\n'
         "}")
    if not dynamic:
        q += ("\n\nIMPORTANT CONTEXT: This is a STATIC stretch / yoga / foam-rolling / "
              "joint-CARs illustration — NOT a 2-step movement. It is CORRECT for it to have "
              "AT MOST ONE arrow (or none) with a single short label such as 'Hold 30s', "
              "'Roll', or 'Circle'. Judge accordingly: set has_labeled_arrows and "
              "every_arrow_labeled = true if there is 0 or 1 such arrow; set no_stray_text = "
              "true as long as there is no text beyond that single short label; set "
              "labels_legible_correct = true if any present label is legible. Do NOT require "
              "two numbered arrows. Focus on: correct held position, only the worked muscle red, "
              "and (for foam-rolling) the roller placed under the correct muscle.")
    data = post(VAL_MODEL, {
        "contents": [{"parts": [
            {"inlineData": {"mimeType": "image/png", "data": img_b64}},
            {"text": q},
        ]}],
        "generationConfig": {"responseModalities": ["TEXT"], "responseMimeType": "application/json"},
    })
    um = data.get("usageMetadata", {})
    COST["val"] += um.get("promptTokenCount", 0) * 0.10e-6 + um.get("candidatesTokenCount", 0) * 0.40e-6
    txt = ""
    for cand in data.get("candidates", []):
        for p in cand.get("content", {}).get("parts", []):
            if "text" in p: txt += p["text"]
    try:
        v = json.loads(txt[txt.find("{"):txt.rfind("}")+1])
    except Exception:
        return {"verdict": "fail", "notes": "validator returned unparseable output", "_raw": txt[:150]}
    # Per-style QA: only DYNAMIC poses must satisfy the exactly-2-labeled-arrows
    # rules. Static stretches / yoga / foam-rolling (smr) / CARs use 0-1 arrow,
    # so we drop the arrow-related HARD checks for them.
    hard = list(HARD)
    if not dynamic:
        hard = [k for k in hard if k not in
                ("has_labeled_arrows", "every_arrow_labeled", "labels_legible_correct")]
    hard_ok = all(bool(v.get(k)) for k in hard)
    if hard_ok and v.get("pose_matches_exercise"):
        v["verdict"] = "pass"
    elif hard_ok:
        v["verdict"] = "review"
    else:
        v["verdict"] = "fail"
    return v

VMARK = {"pass": "✅ Pass", "review": "⚠️ Review", "fail": "❌ Fail"}

def update_tracker(fn, gen_mark, val_mark):
    lines = open(TRACKER).read().split("\n")
    needle = f"`{fn}`"
    for i, ln in enumerate(lines):
        if needle in ln and ln.strip().startswith("|"):
            cells = ln.split("|")
            # cells: ['', #, name, target, equip, filename, genpath, ImgGen, Validation, S3, '']
            if len(cells) >= 10:
                cells[7] = f" {gen_mark} "
                cells[8] = f" {val_mark} "
                lines[i] = "|".join(cells)
                break
    open(TRACKER, "w").write("\n".join(lines))

def already_done(fn):
    # Skip only if validation already reached an acceptable verdict (pass/review).
    # A generated-but-failed/unvalidated row must reprocess.
    needle = f"`{fn}`"
    for ln in open(TRACKER):
        if needle in ln and ln.strip().startswith("|"):
            cells = ln.split("|")
            if len(cells) >= 9 and ("✅" in cells[8] or "⚠️" in cells[8]):
                return True
    return False

RESULTS = os.path.join(BASE, "results")
os.makedirs(RESULTS, exist_ok=True)
PER_EX_TIMEOUT = 150   # seconds backstop per exercise

class _Timeout(Exception): pass
def _on_alarm(sig, frm): raise _Timeout()

def process_one(r, path):
    pd = pose_desc(r)   # one coach-grade pose + exact muscle, reused across regen attempts
    verdict = {"verdict": "fail", "notes": "no attempt"}
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            ok = generate(r, path, pd)
            if not ok:
                verdict = {"verdict": "fail", "notes": "no image returned"}; continue
            verdict = validate(r, path, pd)
        except Exception as e:
            verdict = {"verdict": "fail", "notes": f"error: {e}"}; time.sleep(2); continue
        if verdict["verdict"] in ("pass", "review"):
            break
    if verdict["verdict"] in ("pass", "review") and os.path.exists(path):
        try:
            brand_stamp.stamp(path)   # crisp logo only on images that cleared QA
        except Exception as e:
            print(f"    (logo stamp failed: {e})", flush=True)
    return verdict

def _done_set(rf):
    s = set()
    if os.path.exists(rf):
        for ln in open(rf):
            try:
                j = json.loads(ln)
                if j.get("verdict") in ("pass", "review"):
                    s.add(j["fn"])
            except Exception:
                pass
    return s

def merge():
    recs = {}
    for f in sorted(glob.glob(os.path.join(RESULTS, "worker_*.jsonl"))):
        for ln in open(f):
            try:
                j = json.loads(ln); recs[j["fn"]] = j   # last record wins
            except Exception:
                pass
    lines = open(TRACKER).read().split("\n")
    for i, ln in enumerate(lines):
        if not (ln.strip().startswith("|") and "`" in ln):
            continue
        cells = ln.split("|")
        if len(cells) < 10:
            continue
        # filename = the backticked cell (column index differs across tracker
        # formats); status cols are the last three data cells (…|ImgGen|Val|S3|).
        fn_cell = next((c for c in cells if c.strip().startswith("`")), None)
        if not fn_cell:
            continue
        fn = fn_cell.strip().strip("`")
        if fn in recs:
            j = recs[fn]
            cells[-4] = " ✅ Done " if j.get("generated") else " ❌ Failed "
            cells[-3] = f" {VMARK.get(j['verdict'], '❌ Fail')} "
            lines[i] = "|".join(cells)
    open(TRACKER, "w").write("\n".join(lines))
    tally = {}
    for j in recs.values():
        tally[j["verdict"]] = tally.get(j["verdict"], 0) + 1
    print("MERGED", len(recs), "results. Tally:", tally)
    print("REVIEW:", sorted(j["name"] for j in recs.values() if j["verdict"] == "review"))
    print("FAIL:", sorted(j["name"] for j in recs.values() if j["verdict"] == "fail"))

def main():
    a = sys.argv
    global TRACKER, RESULTS
    if "--tracker" in a:
        t = a[a.index("--tracker") + 1]
        TRACKER = t if os.path.isabs(t) else os.path.join(BASE, t)
    cand_path = a[a.index("--candidates") + 1] if "--candidates" in a else None
    if cand_path:
        if not os.path.isabs(cand_path):
            cand_path = os.path.join(BASE, cand_path)
        RESULTS = os.path.join(BASE, "results_candidates")
        if "--tracker" not in a:
            TRACKER = os.path.join(BASE, "missing_warmup_stretch_tracker.md")
    if "--results" in a:
        rdir = a[a.index("--results") + 1]
        RESULTS = rdir if os.path.isabs(rdir) else os.path.join(BASE, rdir)
    if cand_path:
        os.makedirs(RESULTS, exist_ok=True)
    if "--merge" in a:
        return merge()
    shard, nshard = 0, 1
    if "--shard" in a:
        shard, nshard = map(int, a[a.index("--shard") + 1].split("/"))
    limit = int(a[a.index("--limit") + 1]) if "--limit" in a else None
    timeout = int(a[a.index("--timeout") + 1]) if "--timeout" in a else PER_EX_TIMEOUT
    signal.signal(signal.SIGALRM, _on_alarm)

    only = None
    if "--only" in a:
        only = set(x.strip() for x in open(a[a.index("--only") + 1]).read().split("\n") if x.strip())

    rows = load_candidates(cand_path) if cand_path else load_rows()
    if only is not None:
        mine = [r for i, r in enumerate(rows) if slug(r["name"]) in only and i % nshard == shard]
    else:
        mine = [r for i, r in enumerate(rows) if i % nshard == shard]
    rf = os.path.join(RESULTS, f"worker_{shard}.jsonl")
    skip = set() if only is not None else _done_set(rf)   # in --only mode, force reprocess
    out = open(rf, "a"); done = 0
    for r in mine:
        fn = slug(r["name"]) + ".png"
        if fn in skip:
            continue
        if limit is not None and done >= limit:
            break
        path = os.path.join(GENDIR, fn)
        signal.alarm(timeout)
        try:
            verdict = process_one(r, path)
        except _Timeout:
            verdict = {"verdict": "fail", "notes": f"timeout >{timeout}s"}
        finally:
            signal.alarm(0)
        rec = {"fn": fn, "name": r["name"], "verdict": verdict["verdict"],
               "generated": os.path.exists(path), "notes": verdict.get("notes", "")[:160]}
        out.write(json.dumps(rec) + "\n"); out.flush()
        done += 1
        print(f"[w{shard}:{done}] {r['name']:<38} -> {verdict['verdict'].upper():6} "
              f"(${COST['gen']+COST['val']:.2f}) {verdict.get('notes','')[:55]}", flush=True)
    print(f"[w{shard}] finished {done}. cost ${COST['gen']+COST['val']:.2f}", flush=True)

if __name__ == "__main__":
    main()
