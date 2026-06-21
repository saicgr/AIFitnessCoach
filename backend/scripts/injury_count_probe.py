"""Targeted live probe: does an injured user get a FULL workout of REAL exercises
for a 60-minute session? Prints actual exercise names + stretch count + total.

Reuses the harness's user-lifecycle helpers. Sets duration=60 explicitly.
"""
import asyncio
import json
import sys

import asyncpg
import httpx

import injury_test_harness as H


async def set_profile_60(pool, public_id, injuries, equip, level, focus):
    # Mirror harness set_profile but force a 60-minute session + the given injuries.
    await pool.execute(
        """update public.users set
             fitness_level=$2, goals=$3, equipment_v2=$4,
             active_injuries=$5, preferences=$6, onboarding_completed=true
           where id=$1""",
        public_id, level, json.dumps(["build_muscle"]),
        equip, json.dumps(injuries),
        json.dumps({"workout_duration": 60, "session_duration_minutes": 60}),
    )


async def probe(client, pool, env, injuries, focus):
    email = f"injcount-{abs(hash((tuple(injuries), focus))) % 9000}@zealova.invalid"
    supa, svc = env["SUPABASE_URL"], env["SUPABASE_KEY"]
    token, auth_id = await H.admin_user(client, supa, svc, email)
    if not token:
        print(f"  AUTH_FAIL for {injuries}"); return
    try:
        r = await client.post(f"{H.BASE}/users/auth/sync",
                              headers={"Authorization": f"Bearer {token}"}, json={})
        public_id = r.json().get("id")
        await set_profile_60(pool, public_id, injuries, H.FULL_GYM, "beginner", focus)
        await pool.execute("delete from public.workouts where user_id=$1", public_id)
        body = {"user_id": public_id, "duration_minutes": 60}
        if focus and focus != "full_body":
            body["focus_areas"] = [focus]
        await client.post(f"{H.BASE}/workouts/generate-stream",
                          headers={"Authorization": f"Bearer {token}", "Accept": "text/event-stream"},
                          json=body, timeout=160)
        rows = await pool.fetch(
            "select exercises_json from public.workouts where user_id=$1 order by scheduled_date limit 1",
            public_id)
        exs = []
        if rows and rows[0]["exercises_json"]:
            data = rows[0]["exercises_json"]
            exs = json.loads(data) if isinstance(data, str) else data
        names = [(e.get("name") or e.get("exercise_name") or "") for e in exs]
        n_stretch = sum(1 for n in names if "stretch" in n.lower())
        print(f"\n  injuries={injuries} focus={focus} duration=60min")
        print(f"  → {len(names)} exercises, {n_stretch} stretches:")
        for n in names:
            print(f"      - {n}")
    finally:
        await H.delete_user(client, supa, svc, auth_id)


async def main():
    env = H.load_env()
    dsn = env["DATABASE_URL"].replace("+asyncpg", "").replace("+psycopg2", "")
    pool = await asyncpg.create_pool(dsn, statement_cache_size=0, min_size=1, max_size=4)
    async with httpx.AsyncClient(timeout=170) as client:
        await probe(client, pool, env, ["knees", "shoulders"], "full_body")
        await probe(client, pool, env, ["lower_back", "knees", "shoulders"], "legs")
    await pool.close()


if __name__ == "__main__":
    asyncio.run(main())
