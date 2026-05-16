"""Idempotent image-corpus builder for the Phase-2 full-sweep validator.

Downloads ~500 real images into:
    backend/scripts/benchmarks/images_corpus/
        single/         100 single-dish photos (Food-101 sample)
        combo/          100 combo / thali / rice+curry photos (Indian food HF dataset)
        menu/           100 restaurant menu photos (Unsplash + Wikimedia Commons)
        multiphoto/     10 sets × 3-5 photos each (Pexels keyword search per meal)
        non_food/       10 non-food control photos
    manifest.json       per-image source / license / original_url

Strategy:
  - Pexels free-tier search API (keyless via direct image URLs from
    image search results pages) and a Pexels API key if `PEXELS_API_KEY`
    is in .env.
  - Wikimedia Commons API (no key, generous rate limit).
  - Unsplash search via their public napi (no key needed for results,
    but reflects on per-IP limits — we cap at ~50 req/min).
  - Open Food Facts fallback for additional combo/regional photos.
  - Each image resized to 768px max edge, JPEG quality 80, capped at
    500 KB. Dedup by perceptual hash so near-duplicates from different
    sources don't double-count.

Idempotent: if a target subfolder has the requested count, skip its
downloads. Pass --force to redownload.

Usage:
    cd backend
    .venv/bin/python scripts/benchmarks/build_corpus.py
    .venv/bin/python scripts/benchmarks/build_corpus.py --force
    .venv/bin/python scripts/benchmarks/build_corpus.py --counts single=50,menu=20
"""
import argparse
import io
import json
import os
import random
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.parse import quote_plus

import requests
from dotenv import load_dotenv
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / ".env")

CORPUS_DIR = Path(__file__).resolve().parent / "images_corpus"
SUBDIRS = {
    "single": 100,
    "combo": 100,
    "menu": 100,
    "multiphoto": 10,   # 10 sets, each with 3-5 photos
    "non_food": 10,
    "buffet": 30,
    "drink": 30,
    "dessert": 30,
}

PEXELS_API_KEY = os.environ.get("PEXELS_API_KEY", "")
USER_AGENT = "Mozilla/5.0 (compatible; ZealovaPhase2BenchBot/1.0)"

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #


def _http_get(url: str, headers: Optional[Dict[str, str]] = None, retries: int = 3, timeout: int = 30) -> Optional[bytes]:
    base_headers = {"User-Agent": USER_AGENT}
    if headers:
        base_headers.update(headers)
    for attempt in range(retries):
        try:
            r = requests.get(url, headers=base_headers, timeout=timeout)
            if r.status_code == 200:
                return r.content
            if r.status_code == 429:
                wait = 2 ** attempt
                print(f"  rate-limited, sleeping {wait}s", flush=True)
                time.sleep(wait)
                continue
            print(f"  GET {url[:80]}… HTTP {r.status_code}", flush=True)
        except Exception as e:
            print(f"  GET {url[:80]}… exc={e}", flush=True)
            time.sleep(1)
    return None


def _http_get_json(url: str, headers: Optional[Dict[str, str]] = None) -> Optional[dict]:
    data = _http_get(url, headers)
    if data is None:
        return None
    try:
        return json.loads(data)
    except Exception:
        return None


def _normalize_image(content: bytes, max_edge: int = 768, quality: int = 80, max_bytes: int = 500_000) -> Optional[bytes]:
    """Resize to max_edge, re-encode as JPEG, ensure under max_bytes."""
    try:
        img = Image.open(io.BytesIO(content))
    except Exception:
        return None
    img = img.convert("RGB")
    w, h = img.size
    scale = min(1.0, max_edge / max(w, h))
    if scale < 1.0:
        img = img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
    out = io.BytesIO()
    q = quality
    while True:
        out.seek(0)
        out.truncate()
        img.save(out, format="JPEG", quality=q, optimize=True)
        if out.tell() <= max_bytes or q <= 50:
            break
        q -= 10
    return out.getvalue()


def _phash(content: bytes) -> str:
    """Simple perceptual hash via Pillow average-hash (no external dep)."""
    try:
        img = Image.open(io.BytesIO(content)).convert("L").resize((8, 8), Image.LANCZOS)
    except Exception:
        return ""
    px = list(img.getdata())
    avg = sum(px) / 64
    return "".join("1" if p >= avg else "0" for p in px)


def _save_image(target_dir: Path, name_hint: str, content: bytes, manifest: Dict, source: Dict) -> bool:
    """Normalize + dedup + save. Returns True if saved."""
    norm = _normalize_image(content)
    if not norm:
        return False
    h = _phash(norm)
    if h and h in manifest.get("_seen_hashes", set()):
        return False  # dup
    target_dir.mkdir(parents=True, exist_ok=True)
    fname = f"{name_hint}.jpg"
    counter = 1
    while (target_dir / fname).exists():
        counter += 1
        fname = f"{name_hint}_{counter}.jpg"
    fpath = target_dir / fname
    fpath.write_bytes(norm)
    manifest.setdefault("_seen_hashes", set()).add(h)
    manifest.setdefault("entries", []).append({
        "filename": fname,
        "subdir": target_dir.name,
        "size_bytes": len(norm),
        "phash": h,
        **source,
    })
    return True


# --------------------------------------------------------------------------- #
# Source: Pexels (with API key — best image quality + tagged search)
# --------------------------------------------------------------------------- #


def fetch_pexels_search(query: str, per_page: int = 80) -> List[dict]:
    if not PEXELS_API_KEY:
        return []
    url = f"https://api.pexels.com/v1/search?query={quote_plus(query)}&per_page={per_page}"
    data = _http_get_json(url, headers={"Authorization": PEXELS_API_KEY})
    if not data:
        return []
    photos = data.get("photos", [])
    return [{
        "url": p["src"]["large"],
        "original_url": p["url"],
        "license": "Pexels License (free)",
        "source": "pexels",
        "query": query,
    } for p in photos]


# --------------------------------------------------------------------------- #
# Source: Unsplash (no key needed for napi photos endpoint)
# --------------------------------------------------------------------------- #


def fetch_unsplash_search(query: str, per_page: int = 30) -> List[dict]:
    url = f"https://unsplash.com/napi/search/photos?query={quote_plus(query)}&per_page={per_page}"
    data = _http_get_json(url)
    if not data:
        return []
    return [{
        "url": r.get("urls", {}).get("regular"),
        "original_url": r.get("links", {}).get("html"),
        "license": "Unsplash License (free)",
        "source": "unsplash",
        "query": query,
    } for r in data.get("results", []) if r.get("urls", {}).get("regular")]


# --------------------------------------------------------------------------- #
# Source: Wikimedia Commons category-members
# --------------------------------------------------------------------------- #


def fetch_wikimedia_category(category: str, limit: int = 50) -> List[dict]:
    api = "https://commons.wikimedia.org/w/api.php"
    # Wikimedia requires a real User-Agent — anonymous requests get HTTP 429.
    headers = {"User-Agent": "ZealovaPhase2BenchBot/1.0 (https://zealova.com; admin@zealova.com)"}
    list_url = f"{api}?action=query&list=categorymembers&cmtitle=Category:{quote_plus(category)}&cmlimit={limit}&cmtype=file&format=json"
    data = _http_get_json(list_url, headers=headers)
    if not data:
        return []
    titles = [m["title"] for m in data.get("query", {}).get("categorymembers", [])]
    out = []
    # Batch by 10 to keep URL under length limits + reduce per-request risk.
    # Use requests.get(params=) so the library handles encoding properly.
    for i in range(0, len(titles), 10):
        batch = titles[i:i + 10]
        params = {
            "action": "query",
            "titles": "|".join(batch),
            "prop": "imageinfo",
            "iiprop": "url",
            "format": "json",
        }
        try:
            r = requests.get(api, params=params, headers=headers, timeout=30)
            if r.status_code != 200:
                continue
            meta = r.json()
        except Exception:
            continue
        pages = meta.get("query", {}).get("pages", {})
        for page in pages.values():
            ii = (page.get("imageinfo") or [{}])[0]
            url = ii.get("url")
            title = page.get("title", "")
            # Wikimedia tacks `?utm_source=...` onto image URLs — strip query
            # before checking extension. Also skip non-photo formats they keep
            # in the same categories (.djvu / .pdf / .tif).
            url_path = url.split("?", 1)[0].lower() if url else ""
            if url and url_path.endswith((".jpg", ".jpeg", ".png")):
                out.append({
                    "url": url,
                    "original_url": f"https://commons.wikimedia.org/wiki/{quote_plus(title)}",
                    "license": "Wikimedia Commons (CC variants)",
                    "source": "wikimedia",
                    "query": category,
                })
    return out


# --------------------------------------------------------------------------- #
# Source: Foodish API (free random food images, no auth)
# --------------------------------------------------------------------------- #


# Foodish has 9 food categories. Each call returns ONE random image URL.
FOODISH_CATEGORIES = [
    "biryani", "burger", "butter-chicken", "dessert", "dosa",
    "idly", "pasta", "pizza", "rice", "samosa",
]


def fetch_foodish(category: str, n: int = 10) -> List[dict]:
    """Hit Foodish API n times to get n random images for a category."""
    out = []
    for _ in range(n):
        data = _http_get_json(f"https://foodish-api.com/api/images/{category}")
        if data and data.get("image"):
            out.append({
                "url": data["image"],
                "original_url": data["image"],
                "license": "Foodish API (free)",
                "source": "foodish",
                "query": category,
            })
    return out


# --------------------------------------------------------------------------- #
# Source: thecocktaildb / themealdb (free, no auth, returns CDN image URLs)
# --------------------------------------------------------------------------- #


def fetch_themealdb_search(query: str) -> List[dict]:
    """themealdb returns 1-25 dishes per search with CDN image URL."""
    data = _http_get_json(f"https://www.themealdb.com/api/json/v1/1/search.php?s={quote_plus(query)}")
    if not data or not data.get("meals"):
        return []
    return [{
        "url": m.get("strMealThumb"),
        "original_url": f"https://www.themealdb.com/meal/{m.get('idMeal')}",
        "license": "TheMealDB (CC variant, free for any use)",
        "source": "themealdb",
        "query": query,
    } for m in data["meals"] if m.get("strMealThumb")]


def fetch_themealdb_random_pool(n: int = 50) -> List[dict]:
    """Hit /random.php n times for variety."""
    out = []
    for _ in range(n):
        data = _http_get_json("https://www.themealdb.com/api/json/v1/1/random.php")
        if data and data.get("meals"):
            m = data["meals"][0]
            if m.get("strMealThumb"):
                out.append({
                    "url": m["strMealThumb"],
                    "original_url": f"https://www.themealdb.com/meal/{m.get('idMeal')}",
                    "license": "TheMealDB (free)",
                    "source": "themealdb_random",
                    "query": m.get("strMeal", ""),
                })
    return out


# --------------------------------------------------------------------------- #
# Per-subdir builders
# --------------------------------------------------------------------------- #


SINGLE_QUERIES = [
    "grilled chicken breast", "salmon fillet", "caesar salad", "scrambled eggs",
    "spaghetti bolognese", "margherita pizza", "burger and fries", "sushi nigiri",
    "tacos al pastor", "pad thai", "chicken curry", "fried rice", "pho noodle soup",
    "ramen bowl", "greek salad", "fish and chips", "lasagna", "tom yum soup",
    "fettuccine alfredo", "beef stir fry",
]

COMBO_QUERIES = [
    "indian thali", "north indian thali", "south indian meal banana leaf",
    "rice and curry sri lankan", "bento box japanese", "korean banchan",
    "chinese family style dinner", "ethiopian food platter", "moroccan tagine spread",
    "mediterranean mezze platter", "mexican combo plate", "buddha bowl quinoa",
    "poke bowl", "burrito bowl chipotle", "english full breakfast",
    "american diner breakfast plate", "bibimbap", "dim sum platter",
    "tapas spanish spread", "vietnamese rice paper rolls platter",
]

MENU_QUERIES = [
    "restaurant menu paper", "chalkboard restaurant menu", "diner menu american",
    "wine list menu", "indian restaurant menu", "italian trattoria menu",
    "french bistro menu chalkboard", "cafe coffee menu board", "fast food menu screen",
    "pizza shop menu wall",
]

MULTIPHOTO_MEALS = [
    "sushi platter assortment", "indian thali plate", "burger fries combo",
    "pasta dish italian", "korean barbecue table", "ramen bowl close up",
    "salad bowl mixed", "smoothie bowl breakfast", "steak dinner plate",
    "vegetable stir fry wok",
]

NON_FOOD_QUERIES = [
    "kitten cat", "city skyline", "mountain landscape", "office desk laptop",
    "running shoes", "houseplant green", "books library",
    "concrete building modern", "dog park walking", "ocean wave",
]


def build_single(corpus_dir: Path, manifest: Dict, target: int = 100):
    """Single-dish images via Wikimedia + Foodish + TheMealDB."""
    target_dir = corpus_dir / "single"
    existing = len(list(target_dir.glob("*.jpg"))) if target_dir.exists() else 0
    needed = target - existing
    if needed <= 0:
        print(f"  single/ already has {existing} (target {target}) — skip")
        return
    print(f"  single/ — fetching ~{needed} images (existing {existing})")
    candidates = []
    # Pexels + Unsplash (will be empty without keys)
    for q in SINGLE_QUERIES:
        candidates.extend(fetch_pexels_search(q, per_page=10))
        candidates.extend(fetch_unsplash_search(q, per_page=10))
    # Foodish — 5 categories × 8 each
    for cat in ("burger", "pasta", "pizza", "rice", "dessert"):
        candidates.extend(fetch_foodish(cat, n=8))
    # TheMealDB — search by single-word terms (their endpoint requires single word)
    for q in ("chicken", "salmon", "beef", "pork", "fish", "shrimp", "lamb", "tofu", "egg"):
        candidates.extend(fetch_themealdb_search(q))
    # TheMealDB random pool for variety
    candidates.extend(fetch_themealdb_random_pool(n=30))
    random.shuffle(candidates)
    saved = 0
    for c in candidates:
        if saved >= needed:
            break
        content = _http_get(c["url"])
        if not content:
            continue
        if _save_image(
            target_dir,
            f"single_{saved + existing:03d}_{c['query'].replace(' ', '_')[:30]}",
            content,
            manifest,
            {k: c[k] for k in ("license", "source", "original_url", "query") if k in c},
        ):
            saved += 1
    print(f"  single/ saved {saved} new images")


def build_combo(corpus_dir: Path, manifest: Dict, target: int = 100):
    target_dir = corpus_dir / "combo"
    existing = len(list(target_dir.glob("*.jpg"))) if target_dir.exists() else 0
    needed = target - existing
    if needed <= 0:
        print(f"  combo/ already has {existing} (target {target}) — skip")
        return
    print(f"  combo/ — fetching ~{needed} images (existing {existing})")
    candidates = []
    for q in COMBO_QUERIES:
        candidates.extend(fetch_pexels_search(q, per_page=10))
        candidates.extend(fetch_unsplash_search(q, per_page=10))
    # Foodish for biryani, dosa, idly, butter-chicken, samosa (perfect for combo/regional)
    for cat in ("biryani", "butter-chicken", "dosa", "idly", "samosa"):
        candidates.extend(fetch_foodish(cat, n=15))
    # TheMealDB for stews / curries / mixed plates
    for q in ("curry", "stew", "noodle", "rice", "pilaf"):
        candidates.extend(fetch_themealdb_search(q))
    # Wikimedia categories for combo plates
    for cat in ("Indian_thalis", "Bento_boxes", "Combination_plates", "Buffets"):
        candidates.extend(fetch_wikimedia_category(cat, limit=15))
    random.shuffle(candidates)
    saved = 0
    for c in candidates:
        if saved >= needed:
            break
        content = _http_get(c["url"])
        if not content:
            continue
        if _save_image(
            target_dir,
            f"combo_{saved + existing:03d}_{c['query'].replace(' ', '_')[:30]}",
            content,
            manifest,
            {k: c[k] for k in ("license", "source", "original_url", "query") if k in c},
        ):
            saved += 1
    print(f"  combo/ saved {saved} new images")


def build_menu(corpus_dir: Path, manifest: Dict, target: int = 100):
    target_dir = corpus_dir / "menu"
    existing = len(list(target_dir.glob("*.jpg"))) if target_dir.exists() else 0
    needed = target - existing
    if needed <= 0:
        print(f"  menu/ already has {existing} (target {target}) — skip")
        return
    print(f"  menu/ — fetching ~{needed} images (existing {existing})")
    candidates = []
    for q in MENU_QUERIES:
        candidates.extend(fetch_pexels_search(q, per_page=15))
        candidates.extend(fetch_unsplash_search(q, per_page=15))
    # Wikimedia is the BEST source for menu photos (lots of vintage/historical menus,
    # plus current restaurant photos). Pull from many menu-related categories.
    for cat in [
        "Food_menus", "1900s_food_menus", "1910s_food_menus", "1920s_food_menus",
        "1930s_food_menus", "1940s_food_menus", "1950s_food_menus",
        "1960s_food_menus", "1970s_food_menus", "1980s_food_menus",
        "1990s_food_menus", "2000s_food_menus", "2010s_food_menus",
        "2020s_food_menus", "Menú_del_día",
    ]:
        candidates.extend(fetch_wikimedia_category(cat, limit=15))
    random.shuffle(candidates)
    saved = 0
    for c in candidates:
        if saved >= needed:
            break
        content = _http_get(c["url"])
        if not content:
            continue
        if _save_image(
            target_dir,
            f"menu_{saved + existing:03d}_{c['query'].replace(' ', '_')[:25]}",
            content,
            manifest,
            {k: c[k] for k in ("license", "source", "original_url", "query") if k in c},
        ):
            saved += 1
    print(f"  menu/ saved {saved} new images")


def build_multiphoto(corpus_dir: Path, manifest: Dict, target_sets: int = 10):
    """Each set is a subfolder with 3-5 photos of (loosely) the same meal."""
    target_dir = corpus_dir / "multiphoto"
    existing_sets = sum(1 for p in target_dir.glob("*") if p.is_dir()) if target_dir.exists() else 0
    needed = target_sets - existing_sets
    if needed <= 0:
        print(f"  multiphoto/ already has {existing_sets} sets — skip")
        return
    print(f"  multiphoto/ — fetching ~{needed} sets")
    saved = 0
    for q in MULTIPHOTO_MEALS:
        if saved >= needed:
            break
        cands = (
            fetch_pexels_search(q, per_page=15)
            + fetch_unsplash_search(q, per_page=15)
            + fetch_foodish(q.split()[0] if q.split()[0] in FOODISH_CATEGORIES else "rice", n=5)
            + fetch_themealdb_search(q.split()[0])
        )
        if len(cands) < 3:
            continue
        random.shuffle(cands)
        set_name = f"set_{existing_sets + saved + 1:02d}_{q.replace(' ', '_')[:30]}"
        set_dir = target_dir / set_name
        n_in_set = 0
        for c in cands:
            if n_in_set >= 4:
                break
            content = _http_get(c["url"])
            if not content:
                continue
            if _save_image(
                set_dir,
                f"img_{n_in_set + 1:02d}",
                content,
                manifest,
                {k: c[k] for k in ("license", "source", "original_url", "query") if k in c},
            ):
                n_in_set += 1
        if n_in_set >= 3:
            saved += 1
            print(f"    set_{saved}: {set_name} ({n_in_set} photos)")
        else:
            # cleanup partial
            for f in set_dir.glob("*"):
                f.unlink()
            if set_dir.exists():
                set_dir.rmdir()
    print(f"  multiphoto/ saved {saved} new sets")


def _build_generic(corpus_dir: Path, manifest: Dict, sub: str, target: int,
                   foodish_cats: List[str], mealdb_terms: List[str],
                   wiki_cats: List[str]):
    """Generic edge-class builder (buffet / drink / dessert)."""
    target_dir = corpus_dir / sub
    existing = len(list(target_dir.glob("*.jpg"))) if target_dir.exists() else 0
    needed = target - existing
    if needed <= 0:
        print(f"  {sub}/ already has {existing} — skip")
        return
    print(f"  {sub}/ — fetching ~{needed} images")
    candidates = []
    for c in foodish_cats:
        candidates.extend(fetch_foodish(c, n=12))
    for q in mealdb_terms:
        candidates.extend(fetch_themealdb_search(q))
    for cat in wiki_cats:
        candidates.extend(fetch_wikimedia_category(cat, limit=20))
    random.shuffle(candidates)
    saved = 0
    for c in candidates:
        if saved >= needed:
            break
        content = _http_get(c["url"])
        if not content:
            continue
        if _save_image(
            target_dir, f"{sub}_{saved + existing:03d}_{c['query'].replace(' ', '_')[:24]}",
            content, manifest,
            {k: c[k] for k in ("license", "source", "original_url", "query") if k in c},
        ):
            saved += 1
    print(f"  {sub}/ saved {saved} new images")


def build_non_food(corpus_dir: Path, manifest: Dict, target: int = 10):
    target_dir = corpus_dir / "non_food"
    existing = len(list(target_dir.glob("*.jpg"))) if target_dir.exists() else 0
    needed = target - existing
    if needed <= 0:
        print(f"  non_food/ already has {existing} — skip")
        return
    print(f"  non_food/ — fetching ~{needed} images")
    candidates = []
    for q in NON_FOOD_QUERIES:
        candidates.extend(fetch_pexels_search(q, per_page=3))
        candidates.extend(fetch_unsplash_search(q, per_page=3))
    # Wikimedia non-food categories — picking real category names
    for cat in ["Cats_in_photographs", "Dogs", "Mountains_(photographs)",
                "Skyscrapers", "Office_furniture", "Houseplants",
                "Bookshelves", "Beaches"]:
        candidates.extend(fetch_wikimedia_category(cat, limit=3))
    random.shuffle(candidates)
    saved = 0
    for c in candidates:
        if saved >= needed:
            break
        content = _http_get(c["url"])
        if not content:
            continue
        if _save_image(
            target_dir,
            f"nonfood_{saved + existing:03d}_{c['query'].replace(' ', '_')[:30]}",
            content,
            manifest,
            {k: c[k] for k in ("license", "source", "original_url", "query") if k in c},
        ):
            saved += 1
    print(f"  non_food/ saved {saved} new images")


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true", help="redownload even if target count met")
    parser.add_argument("--counts", type=str, default="", help="override counts e.g. 'single=50,menu=20'")
    args = parser.parse_args()

    counts = dict(SUBDIRS)
    if args.counts:
        for kv in args.counts.split(","):
            k, v = kv.split("=")
            counts[k.strip()] = int(v)

    if args.force and CORPUS_DIR.exists():
        print(f"--force: NOT deleting {CORPUS_DIR} — manually rm if you want a fresh corpus")

    CORPUS_DIR.mkdir(parents=True, exist_ok=True)
    manifest_path = CORPUS_DIR / "manifest.json"
    if manifest_path.exists() and not args.force:
        manifest = json.loads(manifest_path.read_text())
        manifest["_seen_hashes"] = set(manifest.get("_seen_hashes", []))
    else:
        manifest = {"entries": [], "_seen_hashes": set(), "built_at": time.time()}

    if not PEXELS_API_KEY:
        print("WARNING: PEXELS_API_KEY not in .env — Pexels source will be skipped")
        print("         Get a free key at https://www.pexels.com/api/ (200 req/hr)")

    print(f"Building corpus into {CORPUS_DIR}")
    build_single(CORPUS_DIR, manifest, target=counts["single"])
    build_combo(CORPUS_DIR, manifest, target=counts["combo"])
    build_menu(CORPUS_DIR, manifest, target=counts["menu"])
    build_multiphoto(CORPUS_DIR, manifest, target_sets=counts["multiphoto"])
    build_non_food(CORPUS_DIR, manifest, target=counts["non_food"])
    _build_generic(
        CORPUS_DIR, manifest, "buffet", counts["buffet"],
        foodish_cats=["rice", "dessert", "pizza"],
        mealdb_terms=["platter", "buffet", "sampler", "tapas"],
        wiki_cats=["Buffets", "Smorgasbord", "Hotel_breakfasts"],
    )
    _build_generic(
        CORPUS_DIR, manifest, "drink", counts["drink"],
        foodish_cats=[],
        mealdb_terms=["smoothie", "juice", "shake", "cocktail", "lassi"],
        wiki_cats=["Smoothies", "Milkshakes", "Coffee_drinks", "Cocktails"],
    )
    _build_generic(
        CORPUS_DIR, manifest, "dessert", counts["dessert"],
        foodish_cats=["dessert"],
        mealdb_terms=["cake", "pie", "pudding", "ice cream", "tart"],
        wiki_cats=["Desserts", "Cakes", "Ice_cream"],
    )

    # Persist manifest (set→list for JSON)
    manifest_out = {
        **manifest,
        "_seen_hashes": list(manifest.get("_seen_hashes", set())),
    }
    manifest_path.write_text(json.dumps(manifest_out, indent=2))

    # Summary
    total = 0
    for sub in counts:
        d = CORPUS_DIR / sub
        if not d.exists():
            print(f"  {sub}: 0 / {counts[sub]}")
            continue
        if sub == "multiphoto":
            n_sets = sum(1 for p in d.glob("*") if p.is_dir())
            n_imgs = sum(len(list(p.glob('*.jpg'))) for p in d.glob("*") if p.is_dir())
            print(f"  {sub}: {n_sets} sets / {counts[sub]} ({n_imgs} images total)")
            total += n_imgs
        else:
            n = len(list(d.glob("*.jpg")))
            print(f"  {sub}: {n} / {counts[sub]}")
            total += n
    print(f"TOTAL: {total} images")


if __name__ == "__main__":
    main()
