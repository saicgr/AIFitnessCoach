"""Phase-2 FULL SWEEP validator.

Runs the entire 500+ scenario corpus against the locally-running backend
on port 9876 with the QA reviewer JWT. Records every outcome to CSV and
summarizes pass-rates + latency distributions per category.

Categories:
  - single (image)      → /analyze-image-stream, twice (cold + warm)
  - combo (image)       → /analyze-image-stream, twice (cold + warm)
  - menu (image)        → /analyze-image-stream with analysis_mode=menu, twice
  - multiphoto (set)    → /analyze-images-stream (plural), twice per set
  - text                → /analyze-text-stream, once
  - non_food (image)    → /analyze-image-stream, once (expect NO_FOOD_DETECTED)

Usage:
    cd backend
    .venv/bin/python scripts/benchmarks/run_phase2_full_sweep.py
    .venv/bin/python scripts/benchmarks/run_phase2_full_sweep.py --concurrency 2
    .venv/bin/python scripts/benchmarks/run_phase2_full_sweep.py --skip-categories menu,multiphoto
    .venv/bin/python scripts/benchmarks/run_phase2_full_sweep.py --max-cost-usd 1.50

Outputs:
    backend/scripts/benchmarks/results/run_<UTC-iso>.csv         — per-call rows
    backend/scripts/benchmarks/results/run_<UTC-iso>_summary.md  — headline numbers
    backend/scripts/benchmarks/results/run_<UTC-iso>_window.txt  — bench start/end ISO
                                                                    (read by cleanup script)
"""
import argparse
import asyncio
import csv
import json
import os
import statistics
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import httpx
import requests
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / ".env")
sys.path.insert(0, str(ROOT))

from scripts.benchmarks.text_scenarios import get_scenarios as get_text_scenarios

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]
USER_ID = "d54e6652-fdf1-4ca0-82d1-23d7c02df294"
QA_EMAIL = "reviewer@fitwiz.us"
QA_PASSWORD = "FitWiz2026!"
BASE = os.environ.get("BENCH_BASE", "http://127.0.0.1:9876")

CORPUS_DIR = Path(__file__).resolve().parent / "images_corpus"
RESULTS_DIR = Path(__file__).resolve().parent / "results"

# Cost estimate constants (rough, for budget guard)
COST_PER_VISION_CALL = 0.0005
COST_PER_TEXT_CALL = 0.00015
COST_PER_GEMINI_FALLBACK = 0.0008  # text Stage-2 path

# CSV columns
COLS = [
    "ts", "category", "input_id", "pass_label", "http_status", "final_event",
    "error_code", "elapsed_ms", "n_dishes", "macros_complete",
    "cache_source", "served_by", "calories", "protein_g", "carbs_g", "fat_g",
    "macro_unknown_flag", "notes",
]


def mint_jwt() -> str:
    r = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": SUPABASE_KEY, "Content-Type": "application/json"},
        json={"email": QA_EMAIL, "password": QA_PASSWORD},
        timeout=10,
    )
    r.raise_for_status()
    return r.json()["access_token"]


# --------------------------------------------------------------------------- #
# Per-scenario callers
# --------------------------------------------------------------------------- #


async def time_image_scan(
    client: httpx.AsyncClient,
    token: str,
    image_path: Path,
    pass_label: str,
    analysis_mode: str = "plate",
) -> Dict:
    img_bytes = image_path.read_bytes()
    files = {"image": (image_path.name, img_bytes, "image/jpeg")}
    data = {"user_id": USER_ID, "meal_type": "lunch"}
    if analysis_mode != "plate":
        data["analysis_mode"] = analysis_mode
    return await _call_sse(
        client, token, f"{BASE}/api/v1/nutrition/analyze-image-stream",
        data=data, files=files,
        category=image_path.parent.name, input_id=image_path.name, pass_label=pass_label,
    )


async def time_multi_image_scan(
    client: httpx.AsyncClient,
    token: str,
    image_paths: List[Path],
    pass_label: str,
    analysis_mode: str = "auto",
    category: str = "multiphoto",
) -> Dict:
    # Real endpoint is /log-multi-image-stream (form: images[], analysis_mode,
    # confirm_before_log). NOT /analyze-images-stream (that 404'd last sweep).
    files = []
    for p in image_paths:
        files.append(("images", (p.name, p.read_bytes(), "image/jpeg")))
    data = {
        "user_id": USER_ID, "meal_type": "lunch",
        "analysis_mode": analysis_mode, "confirm_before_log": "true",
    }
    set_name = image_paths[0].parent.name
    return await _call_sse(
        client, token, f"{BASE}/api/v1/nutrition/log-multi-image-stream",
        data=data, files=files,
        category=category, input_id=set_name, pass_label=pass_label,
    )


async def time_recipe_text(client, token, label: str, text: str, idx: int) -> Dict:
    return await _call_sse(
        client, token, f"{BASE}/api/v1/nutrition/recipes/import-text?user_id={USER_ID}",
        data=None, files=None, json_body={"text": text},
        category="recipe_text", input_id=f"r{idx:02d}_{label}", pass_label="cold",
    )


async def time_recipe_url(client, token, label: str, url: str, idx: int) -> Dict:
    return await _call_sse(
        client, token, f"{BASE}/api/v1/nutrition/recipes/import-url?user_id={USER_ID}",
        data=None, files=None, json_body={"url": url},
        category="recipe_url", input_id=f"u{idx:02d}_{label}", pass_label="cold",
    )


async def time_barcode(client, token, label: str, barcode: str, idx: int) -> Dict:
    """Barcode is a plain GET (no SSE) — time it directly."""
    headers = {"Authorization": f"Bearer {token}"}
    t0 = time.perf_counter()
    status = 0
    note = ""
    try:
        r = await client.get(f"{BASE}/api/v1/nutrition/barcode/{barcode}",
                              headers=headers, timeout=25.0)
        status = r.status_code
        if status == 200:
            note = (r.json() or {}).get("product_name", "")[:40]
        else:
            note = r.text[:60]
    except Exception as e:
        note = f"exc:{type(e).__name__}"
    elapsed_ms = (time.perf_counter() - t0) * 1000
    return {
        "ts": datetime.now(timezone.utc).isoformat(),
        "category": "barcode", "input_id": f"b{idx:02d}_{label}", "pass_label": "cold",
        "http_status": status,
        "final_event": "done" if status == 200 else "error",
        "error_code": None if status == 200 else f"HTTP_{status}",
        "elapsed_ms": int(elapsed_ms), "n_dishes": 1 if status == 200 else 0,
        "macros_complete": status == 200, "cache_source": None, "served_by": None,
        "calories": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0,
        "macro_unknown_flag": False, "notes": note,
    }


async def time_text_scan(
    client: httpx.AsyncClient,
    token: str,
    category: str,
    text: str,
    idx: int,
) -> Dict:
    # Text endpoint expects JSON body (LogTextRequest), not form data
    body = {"user_id": USER_ID, "meal_type": "lunch", "description": text}
    return await _call_sse(
        client, token, f"{BASE}/api/v1/nutrition/analyze-text-stream",
        data=None, files=None, json_body=body,
        category=f"text_{category}", input_id=f"t{idx:03d}", pass_label="cold",
    )


async def _call_sse(
    client: httpx.AsyncClient,
    token: str,
    url: str,
    data,
    files,
    category: str,
    input_id: str,
    pass_label: str,
    json_body: Optional[dict] = None,
) -> Dict:
    headers = {"Authorization": f"Bearer {token}"}
    t0 = time.perf_counter()
    last_event = None
    final_payload: Optional[dict] = None
    error_code = None
    cache_source = None
    served_by = None
    n_dishes = 0
    macros_complete = False
    cal = p = c = f = 0
    macro_unknown_flag = False
    http_status = 0
    note = ""
    try:
        kw = {"headers": headers, "timeout": 120.0}
        if json_body is not None:
            kw["json"] = json_body
        if data is not None:
            kw["data"] = data
        if files is not None:
            kw["files"] = files
        async with client.stream("POST", url, **kw) as resp:
            http_status = resp.status_code
            async for line in resp.aiter_lines():
                if not line:
                    continue
                if line.startswith("event:"):
                    last_event = line.split(":", 1)[1].strip()
                elif line.startswith("data:"):
                    try:
                        d = json.loads(line[5:].strip())
                    except Exception:
                        continue
                    # Two SSE shapes:
                    #  - food endpoints: `event: done` / `event: error`
                    #  - recipe import: no event line, `data:{"step":"done"|"error"}`
                    step = d.get("step") if isinstance(d, dict) else None
                    is_terminal = (
                        last_event in ("done", "error")
                        or step in ("done", "error")
                    )
                    if is_terminal:
                        final_payload = d
                        if step in ("done", "error") and not last_event:
                            last_event = step
                        break
    except Exception as e:
        note = f"exc:{type(e).__name__}:{str(e)[:80]}"
    elapsed_ms = (time.perf_counter() - t0) * 1000

    if final_payload:
        # Image-stream and text-stream use slightly different payload shapes.
        # Image-stream wraps in `data` per SSE; text-stream returns directly.
        # Try both.
        body = final_payload.get("data") if isinstance(final_payload.get("data"), dict) else final_payload
        if last_event == "error":
            error_code = (
                body.get("error_code") or final_payload.get("error_code")
                or final_payload.get("message")
            )
        # Recipe import: dishes = ingredient count inside recipe{}
        recipe = body.get("recipe") or final_payload.get("recipe")
        if isinstance(recipe, dict):
            ings = recipe.get("ingredients") or []
            n_dishes = len(ings) if isinstance(ings, list) else 0
            macros_complete = n_dishes > 0
        items = body.get("food_items") or final_payload.get("food_items") or []
        if isinstance(items, list) and items:
            n_dishes = len(items)
            if items:
                first = items[0]
                cal = float(first.get("calories") or 0)
                p = float(first.get("protein_g") or 0)
                c = float(first.get("carbs_g") or 0)
                f = float(first.get("fat_g") or 0)
                macros_complete = (cal > 0) and (p > 0 or c > 0 or f > 0)
                macro_unknown_flag = bool(first.get("_macro_unknown"))
        meta = body.get("_cache_metadata") or final_payload.get("_cache_metadata") or {}
        cache_source = meta.get("served_by_summary")  # may be None — backend logs are richer
        if not cache_source:
            # Heuristic: derive from novel_count / hit counts in metadata
            nov = meta.get("novel_count")
            uc = meta.get("n_user_contributed_hits")
            ca = meta.get("n_canonical_hits")
            if nov is not None or uc is not None or ca is not None:
                cache_source = f"novel={nov},uc={uc},ca={ca}"

    return {
        "ts": datetime.now(timezone.utc).isoformat(),
        "category": category,
        "input_id": input_id,
        "pass_label": pass_label,
        "http_status": http_status,
        "final_event": last_event or "?",
        "error_code": error_code,
        "elapsed_ms": int(elapsed_ms),
        "n_dishes": n_dishes,
        "macros_complete": macros_complete,
        "cache_source": cache_source,
        "served_by": served_by,
        "calories": cal,
        "protein_g": p,
        "carbs_g": c,
        "fat_g": f,
        "macro_unknown_flag": macro_unknown_flag,
        "notes": note,
    }


# --------------------------------------------------------------------------- #
# Sweep orchestration
# --------------------------------------------------------------------------- #


async def run_sweep(
    skip_categories: List[str],
    concurrency: int,
    max_per_category: Optional[int],
    csv_writer,
    flush_csv,
) -> List[Dict]:
    rows: List[Dict] = []
    sem = asyncio.Semaphore(concurrency)
    token = mint_jwt()

    def categorize_text(t_idx: int, t_cat: str) -> str:
        return t_cat

    async with httpx.AsyncClient() as client:

        # ----- Image categories (single-image /analyze-image-stream) -----
        for category, mode in [
            ("single", "plate"),
            ("combo", "plate"),
            ("buffet", "buffet"),
            ("drink", "plate"),
            ("dessert", "plate"),
            ("synthetic", "plate"),
            ("non_food", "plate"),
        ]:
            if category in skip_categories:
                print(f"  skip {category}")
                continue
            cat_dir = CORPUS_DIR / category
            if not cat_dir.exists():
                print(f"  {category}/ not found — skip")
                continue
            images = sorted(cat_dir.glob("*.jpg"))
            if max_per_category:
                images = images[:max_per_category]
            # non_food + synthetic run once (resilience/reject — no warm value)
            single_pass_cats = ("non_food", "synthetic")
            n_passes = 1 if category in single_pass_cats else 2
            print(f"  {category} — {len(images)} images × {n_passes} pass(es)")

            async def _do_image(p: Path, plabel: str, m=mode):
                async with sem:
                    return await time_image_scan(client, token, p, plabel, analysis_mode=m)

            # Cold pass first
            cold_tasks = [asyncio.create_task(_do_image(img, "cold")) for img in images]
            for done in asyncio.as_completed(cold_tasks):
                r = await done
                rows.append(r)
                csv_writer.writerow([r[c] for c in COLS])
                flush_csv()
            # Warm pass
            if n_passes > 1:
                warm_tasks = [asyncio.create_task(_do_image(img, "warm")) for img in images]
                for done in asyncio.as_completed(warm_tasks):
                    r = await done
                    rows.append(r)
                    csv_writer.writerow([r[c] for c in COLS])
                    flush_csv()

        async def _drain(tasks):
            for done in asyncio.as_completed(tasks):
                r = await done
                rows.append(r)
                csv_writer.writerow([r.get(c) for c in COLS])
                flush_csv()

        # ----- Multi-photo sets (/log-multi-image-stream, mode=auto) -----
        if "multiphoto" not in skip_categories:
            mp_dir = CORPUS_DIR / "multiphoto"
            if mp_dir.exists():
                sets = [p for p in sorted(mp_dir.glob("*")) if p.is_dir()]
                if max_per_category:
                    sets = sets[:max_per_category]
                print(f"  multiphoto — {len(sets)} sets × 1 pass")
                async def _do_mp(s: Path):
                    async with sem:
                        imgs = sorted(s.glob("*.jpg"))
                        return await time_multi_image_scan(
                            client, token, imgs, "cold",
                            analysis_mode="auto", category="multiphoto")
                await _drain([asyncio.create_task(_do_mp(s)) for s in sets])

        # ----- Menu scan (/log-multi-image-stream, mode=menu) -----
        if "menu" not in skip_categories:
            menu_dir = CORPUS_DIR / "menu"
            if menu_dir.exists():
                menus = sorted(menu_dir.glob("*.jpg"))
                if max_per_category:
                    menus = menus[:max_per_category]
                print(f"  menu — {len(menus)} images × 1 pass")
                async def _do_menu(p: Path):
                    async with sem:
                        return await time_multi_image_scan(
                            client, token, [p], "cold",
                            analysis_mode="menu", category="menu")
                await _drain([asyncio.create_task(_do_menu(m)) for m in menus])

        # ----- Recipe import: text + url -----
        if "recipe" not in skip_categories:
            from scripts.benchmarks.recipe_corpus import get_text_recipes, get_url_recipes
            txt_recipes = get_text_recipes()
            url_recipes = get_url_recipes()
            if max_per_category:
                txt_recipes = txt_recipes[:max_per_category]
                url_recipes = url_recipes[:max_per_category]
            print(f"  recipe — {len(txt_recipes)} text + {len(url_recipes)} url")
            async def _do_rtext(i, label, text):
                async with sem:
                    return await time_recipe_text(client, token, label, text, i)
            async def _do_rurl(i, label, url):
                async with sem:
                    return await time_recipe_url(client, token, label, url, i)
            await _drain([asyncio.create_task(_do_rtext(i, l, t))
                          for i, (l, t) in enumerate(txt_recipes)])
            await _drain([asyncio.create_task(_do_rurl(i, l, u))
                          for i, (l, u) in enumerate(url_recipes)])

        # ----- Barcode -----
        if "barcode" not in skip_categories:
            from scripts.benchmarks.barcode_list import get_barcodes
            barcodes = get_barcodes()
            if max_per_category:
                barcodes = barcodes[:max_per_category]
            print(f"  barcode — {len(barcodes)} lookups")
            async def _do_bc(i, label, code):
                async with sem:
                    return await time_barcode(client, token, label, code, i)
            await _drain([asyncio.create_task(_do_bc(i, l, c))
                          for i, (l, c) in enumerate(barcodes)])

        # ----- Text scenarios -----
        if "text" not in skip_categories:
            text_scenarios = get_text_scenarios()
            if max_per_category:
                text_scenarios = text_scenarios[:max_per_category]
            print(f"  text — {len(text_scenarios)} scenarios × 1 pass")
            async def _do_text(idx: int, cat: str, txt: str):
                async with sem:
                    return await time_text_scan(client, token, cat, txt, idx)
            tasks = [asyncio.create_task(_do_text(i, c, t)) for i, (c, t) in enumerate(text_scenarios)]
            for done in asyncio.as_completed(tasks):
                r = await done
                rows.append(r)
                csv_writer.writerow([r[c] for c in COLS])
                flush_csv()

    return rows


# --------------------------------------------------------------------------- #
# Reporting
# --------------------------------------------------------------------------- #


def _percentile(xs: List[int], pct: float) -> Optional[int]:
    if not xs:
        return None
    xs = sorted(xs)
    k = max(0, min(len(xs) - 1, int(round(len(xs) * pct / 100)) - 1))
    return xs[k]


def write_summary(rows: List[Dict], summary_path: Path, t_start: str, t_end: str):
    by_category: Dict[str, List[Dict]] = {}
    for r in rows:
        by_category.setdefault(r["category"], []).append(r)

    lines = [
        f"# Phase-2 Full Sweep Summary",
        "",
        f"Bench window: {t_start} → {t_end}",
        f"Total scenarios run: {len(rows)}",
        "",
        "## Per-category outcomes",
        "",
        "| Category | Pass | n | done% | err% | macros% | cold p50 | cold p95 | warm p50 | warm p95 |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    for cat in sorted(by_category):
        for plabel in ("cold", "warm"):
            subset = [r for r in by_category[cat] if r["pass_label"] == plabel]
            if not subset:
                continue
            n = len(subset)
            done = sum(1 for r in subset if r["final_event"] == "done")
            err = sum(1 for r in subset if r["final_event"] == "error")
            macros = sum(1 for r in subset if r["macros_complete"])
            cold = [r["elapsed_ms"] for r in subset if r["pass_label"] == "cold"]
            warm = [r["elapsed_ms"] for r in subset if r["pass_label"] == "warm"]
            lines.append(
                f"| {cat} | {plabel} | {n} | "
                f"{done*100//n}% | {err*100//n}% | {macros*100//n}% | "
                f"{_percentile(cold, 50) or '-'}ms | {_percentile(cold, 95) or '-'}ms | "
                f"{_percentile(warm, 50) or '-'}ms | {_percentile(warm, 95) or '-'}ms |"
            )

    # Top error codes
    err_rows = [r for r in rows if r["error_code"]]
    if err_rows:
        from collections import Counter
        top = Counter(r["error_code"] for r in err_rows).most_common(10)
        lines.append("\n## Top error codes\n")
        for code, n in top:
            lines.append(f"- `{code}` × {n}")

    # Slowest 10 successful scans
    slow = sorted(
        [r for r in rows if r["final_event"] == "done"],
        key=lambda r: -r["elapsed_ms"],
    )[:10]
    if slow:
        lines.append("\n## Slowest 10 successful scans\n")
        for r in slow:
            lines.append(
                f"- {r['category']} / {r['input_id']} ({r['pass_label']}): "
                f"{r['elapsed_ms']}ms, {r['n_dishes']} dishes, "
                f"macros_complete={r['macros_complete']}"
            )

    # Macro completeness drilldown
    incomplete = [r for r in rows if r["final_event"] == "done" and not r["macros_complete"]]
    if incomplete:
        lines.append(f"\n## Macro-incomplete done scans: {len(incomplete)}\n")
        from collections import Counter
        by_cat = Counter(r["category"] for r in incomplete)
        for cat, n in by_cat.most_common():
            lines.append(f"- {cat}: {n}")

    summary_path.write_text("\n".join(lines))


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--concurrency", type=int, default=2, help="parallel requests (1-4)")
    p.add_argument("--skip-categories", type=str, default="", help="comma list: single,combo,menu,multiphoto,text,non_food")
    p.add_argument("--max-per-category", type=int, default=None, help="cap N per category for smoke runs")
    p.add_argument("--max-cost-usd", type=float, default=2.0, help="abort if est cost exceeds this")
    args = p.parse_args()
    args.concurrency = max(1, min(4, args.concurrency))

    skip = [s.strip() for s in args.skip_categories.split(",") if s.strip()]

    # Liveness check
    try:
        rs = requests.get(BASE, timeout=5)
        if rs.status_code != 200:
            print(f"FATAL: {BASE} returned HTTP {rs.status_code}")
            return 1
    except Exception as e:
        print(f"FATAL: cannot reach {BASE}: {e}")
        print("Start the backend first:")
        print("  cd backend && SKIP_INFLAMMATION_PREWARM=1 .venv/bin/python -m uvicorn main:app --host 127.0.0.1 --port 9876 &")
        return 1

    # Cost estimator
    n_images = 0
    for cat in ("single", "combo", "menu", "non_food"):
        if cat in skip:
            continue
        d = CORPUS_DIR / cat
        if d.exists():
            cnt = len(list(d.glob("*.jpg")))
            if args.max_per_category:
                cnt = min(cnt, args.max_per_category)
            n_images += cnt * (1 if cat == "non_food" else 2)
    if "multiphoto" not in skip:
        d = CORPUS_DIR / "multiphoto"
        if d.exists():
            n_sets = sum(1 for p in d.glob("*") if p.is_dir())
            if args.max_per_category:
                n_sets = min(n_sets, args.max_per_category)
            n_images += n_sets * 2
    n_text = 100
    if "text" in skip:
        n_text = 0
    if args.max_per_category and n_text:
        n_text = min(n_text, args.max_per_category)

    est_cost = n_images * COST_PER_VISION_CALL + n_text * COST_PER_TEXT_CALL
    est_time_min = (n_images * 8 + n_text * 1) / 60 / args.concurrency  # rough
    print(f"Estimated: {n_images} image calls + {n_text} text calls")
    print(f"Estimated cost: ${est_cost:.2f}")
    print(f"Estimated time: {est_time_min:.1f} min at concurrency={args.concurrency}")
    if est_cost > args.max_cost_usd:
        print(f"ABORT: estimated cost ${est_cost:.2f} > --max-cost-usd ${args.max_cost_usd:.2f}")
        return 1

    # Setup CSV + window file
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    iso = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    csv_path = RESULTS_DIR / f"run_{iso}.csv"
    summary_path = RESULTS_DIR / f"run_{iso}_summary.md"
    window_path = RESULTS_DIR / f"run_{iso}_window.txt"

    t_start = datetime.now(timezone.utc).isoformat()
    print(f"\nStart: {t_start}")
    print(f"CSV:   {csv_path}")

    fh = open(csv_path, "w", newline="")
    writer = csv.writer(fh)
    writer.writerow(COLS)
    fh.flush()

    rows = asyncio.run(run_sweep(
        skip_categories=skip,
        concurrency=args.concurrency,
        max_per_category=args.max_per_category,
        csv_writer=writer,
        flush_csv=fh.flush,
    ))
    fh.close()

    t_end = datetime.now(timezone.utc).isoformat()
    window_path.write_text(f"start={t_start}\nend={t_end}\nuser_id={USER_ID}\n")
    write_summary(rows, summary_path, t_start, t_end)
    print(f"\nDone: {t_end}")
    print(f"Summary: {summary_path}")

    # Quick stdout headlines
    done = sum(1 for r in rows if r["final_event"] == "done")
    err = sum(1 for r in rows if r["final_event"] == "error")
    macros = sum(1 for r in rows if r["macros_complete"])
    print(f"\nHeadlines: {done} done / {err} error / {macros} macros-complete out of {len(rows)} total")
    return 0


if __name__ == "__main__":
    sys.exit(main())
