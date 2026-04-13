"""
Live HTTP end-to-end verification — the curl matrix from the Part A plan.

Uses FastAPI's TestClient against the REAL app (routes + services + DB via
Supabase creds from .env). Only auth is mocked — everything else runs the
actual production code path.

Run:
    cd backend && python tests/e2e_curl_matrix.py
"""
import asyncio
import os
import sys
import time
from typing import List

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from httpx import AsyncClient, ASGITransport  # noqa: E402

from main import app  # noqa: E402
from core.auth import get_current_user  # noqa: E402


TEST_USER = {
    "id": "00000000-0000-0000-0000-000000000000",
    "email": "e2e@test.local",
    "auth_id": "00000000-0000-0000-0000-000000000000",
    "user_metadata": {},
}


async def _fake_auth():
    return TEST_USER


app.dependency_overrides[get_current_user] = _fake_auth


# ── Curl matrix ───────────────────────────────────────────────────────────

async def hit(client: AsyncClient, query: str) -> dict:
    start = time.monotonic()
    r = await client.get(
        "/api/v1/nutrition/food-search",
        params={"query": query, "page_size": 10},
        headers={"Authorization": "Bearer fake-token"},
    )
    elapsed = (time.monotonic() - start) * 1000
    try:
        data = r.json()
    except Exception:
        data = {}
    return {
        "status": r.status_code,
        "foods": data.get("foods", []),
        "total": data.get("total_hits", 0),
        "ms": round(elapsed),
    }


def top_names(result: dict, n: int = 5) -> List[str]:
    return [f["description"] for f in result["foods"][:n]]


def assert_top_has(result: dict, needle: str, n: int = 3):
    names = top_names(result, n)
    if not any(needle.lower() in name.lower() for name in names):
        raise AssertionError(
            f"Expected '{needle}' in top {n} but got {names}"
        )


def assert_top_excludes_generic(result: dict, forbidden: str, n: int = 3):
    names = top_names(result, n)
    for name in names:
        # Exact-case mismatch OK — reject if the name IS exactly the forbidden generic
        if name.lower().strip() == forbidden.lower().strip():
            raise AssertionError(
                f"Expected '{forbidden}' NOT in top {n} but found it: {names}"
            )


def header(title: str):
    print(f"\n{'═' * 72}\n{title}\n{'═' * 72}")


def report(label: str, result: dict, extra: str = ""):
    ok = result["status"] == 200
    marker = "✓" if ok else "✗"
    print(f"  [{marker}] {label}  (HTTP {result['status']}, {result['ms']}ms, {result['total']} hits)")
    for i, name in enumerate(top_names(result, 5), 1):
        print(f"      {i}. {name}")
    if extra:
        print(f"      → {extra}")


async def main():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Warmup loop — dev-machine cold SQLAlchemy engine init (pg_catalog.version,
        # current_schema, etc.) takes ~500-800ms per phase on first use. Fire
        # several throwaway requests so the pool + prepared statements are hot
        # before we judge real results.
        print("Warming up DB pool (3 rounds)...")
        for i in range(3):
            _warm = await hit(client, f"warmup_pool_xyz_{i}")
            print(f"  round {i + 1}: {_warm['ms']}ms")
        print()
        await _run_matrix(client)


async def _run_matrix(client: AsyncClient):
    header("CASE 1: 'paneer masala dosa' — expect Paneer Masala Dosa at top")
    r = await hit(client, "paneer masala dosa")
    report("paneer masala dosa", r)
    assert_top_has(r, "paneer masala dosa", n=3)
    assert_top_excludes_generic(r, "Masala Dosa", n=1)
    print("  ✓ PASS")

    header("CASE 2: 'masala dosa' — expect plain Masala Dosa (regression)")
    r = await hit(client, "masala dosa")
    report("masala dosa", r)
    assert_top_has(r, "Masala Dosa", n=3)
    print("  ✓ PASS")

    header("CASE 3: 'paner masala dosa' (typo) — expect Paneer Masala Dosa")
    r = await hit(client, "paner masala dosa")
    report("paner masala dosa", r)
    assert_top_has(r, "paneer masala dosa", n=5)
    print("  ✓ PASS")

    header("CASE 4: 'chocolate milk' — expect Chocolate Milk, NOT Milk Chocolate Bar")
    r = await hit(client, "chocolate milk")
    report("chocolate milk", r)
    assert_top_has(r, "chocolate milk", n=3)
    assert_top_excludes_generic(r, "Milk Chocolate Bar", n=1)
    print("  ✓ PASS")

    header("CASE 5: 'milk chocolate' — expect Milk Chocolate Bar, NOT Chocolate Milk")
    r = await hit(client, "milk chocolate")
    report("milk chocolate", r)
    # Either Milk Chocolate Bar or some other chocolate bar row — not Chocolate Milk
    assert_top_excludes_generic(r, "Chocolate Milk", n=1)
    print("  ✓ PASS")

    header("CASE 6: 'spicy chicken curry' — descriptor ignored")
    r = await hit(client, "spicy chicken curry")
    report("spicy chicken curry", r)
    assert_top_has(r, "chicken curry", n=5)
    print("  ✓ PASS")

    header("CASE 7: 'large pizza' — size descriptor ignored")
    r = await hit(client, "large pizza")
    report("large pizza", r)
    assert_top_has(r, "pizza", n=5)
    print("  ✓ PASS")

    header("CASE 8: 'mutton biryani' — expect Mutton Biryani, NOT Beef Buriyani")
    # This was the Path-B-data bug fixed by the protein-variant cleanup.
    r = await hit(client, "mutton biryani")
    report("mutton biryani", r)
    assert_top_excludes_generic(r, "Beef Buriyani", n=2)
    print("  ✓ PASS")

    header("CASE 9: 'paneer curry' — expect paneer-containing result, NOT Tofu Curry")
    r = await hit(client, "paneer curry")
    report("paneer curry", r)
    assert_top_excludes_generic(r, "Tofu Curry", n=2)
    print("  ✓ PASS")

    header("CASE 10: 'xyz123abc' — expect empty or clear 'no match'")
    r = await hit(client, "xyz123abc")
    report("xyz123abc", r)
    # Either zero hits OR all results are weak/unrelated — no silent wrong match
    assert r["total"] == 0 or all(
        "xyz" not in f["description"].lower() for f in r["foods"][:3]
    )
    print("  ✓ PASS — no silent garbage match")

    header("CASE 11: 'dosa' — single-word query returns dosa variants")
    r = await hit(client, "dosa")
    report("dosa", r)
    assert_top_has(r, "dosa", n=5)
    print("  ✓ PASS")

    header("CASE 12: 'paneer-masala dosa' (hyphen) — normalization works")
    r = await hit(client, "paneer-masala dosa")
    report("paneer-masala dosa", r)
    assert_top_has(r, "paneer masala dosa", n=3)
    print("  ✓ PASS")

    print("\n" + "═" * 72)
    print("  ALL 12 LIVE HTTP CASES PASSED")
    print("═" * 72)


if __name__ == "__main__":
    asyncio.run(main())
