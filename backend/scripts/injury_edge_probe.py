"""Edge-case probe: the MOST injury-constrained generations. Confirms a user is
never left with an empty / 500 / stretch-dominated / absurdly-thin workout.

Scenarios (the corners that stress injury × exercise-count):
  - bodyweight-only + triple injury + 90 min legs (no machines, long session)
  - full_gym + ALL 8 joints injured + 60 min full_body (maximal constraint)
  - bodyweight + shoulders+wrists+elbows + push (no safe upper push)
"""
import asyncio
import json

import asyncpg
import httpx

import injury_test_harness as H


async def set_profile(pool, public_id, injuries, equip, level, duration):
    await pool.execute(
        """update public.users set
             fitness_level=$2, goals=$3, equipment_v2=$4,
             active_injuries=$5, preferences=$6, onboarding_completed=true
           where id=$1""",
        public_id, level, json.dumps(["build_muscle"]),
        equip, json.dumps(injuries),
        json.dumps({"workout_duration": duration, "session_duration_minutes": duration}),
    )


async def probe(client, pool, env, label, injuries, equip, level, focus, duration):
    email = f"injedge-{abs(hash(label)) % 9000}@zealova.invalid"
    supa, svc = env["SUPABASE_URL"], env["SUPABASE_KEY"]
    token, auth_id = await H.admin_user(client, supa, svc, email)
    if not token:
        print(f"  {label}: AUTH_FAIL"); return
    try:
        r = await client.post(f"{H.BASE}/users/auth/sync",
                              headers={"Authorization": f"Bearer {token}"}, json={})
        public_id = r.json().get("id")
        await set_profile(pool, public_id, injuries, equip, level, duration)
        await pool.execute("delete from public.workouts where user_id=$1", public_id)
        body = {"user_id": public_id, "duration_minutes": duration}
        if focus and focus != "full_body":
            body["focus_areas"] = [focus]
        resp = await client.post(
            f"{H.BASE}/workouts/generate-stream",
            headers={"Authorization": f"Bearer {token}", "Accept": "text/event-stream"},
            json=body, timeout=170)
        err = resp.status_code >= 500 or "event: error" in resp.text
        # read produced workout + leak-check against the safety index
        chk = await H.read_and_check(pool, public_id, injuries)
        names = chk.get("names", [])
        n_stretch = sum(1 for n in names if "stretch" in n.lower())
        leaks = len(chk.get("leaks", []))
        status = ("500/ERR" if err else
                  "EMPTY" if not names else
                  f"LEAK×{leaks}" if leaks else
                  "OK")
        print(f"\n  [{status}] {label}")
        print(f"    {len(names)} exercises ({n_stretch} stretch), duration={duration}min, leaks={leaks}")
        for n in names:
            print(f"      - {n}")
    finally:
        await H.delete_user(client, supa, svc, auth_id)


async def main():
    env = H.load_env()
    dsn = env["DATABASE_URL"].replace("+asyncpg", "").replace("+psycopg2", "")
    pool = await asyncpg.create_pool(dsn, statement_cache_size=0, min_size=1, max_size=4)
    ALL_JOINTS = ["neck", "shoulders", "elbows", "wrists", "lower_back", "hips", "knees", "ankles"]
    async with httpx.AsyncClient(timeout=180) as client:
        await probe(client, pool, env, "bodyweight + triple-injury + 90min legs",
                    ["lower_back", "knees", "shoulders"], H.BODYWEIGHT, "beginner", "legs", 90)
        await probe(client, pool, env, "full_gym + ALL 8 joints + 60min full_body",
                    ALL_JOINTS, H.FULL_GYM, "beginner", "full_body", 60)
        await probe(client, pool, env, "bodyweight + shoulders/wrists/elbows + push",
                    ["shoulders", "wrists", "elbows"], H.BODYWEIGHT, "beginner", "full_body_push", 45)
    await pool.close()


if __name__ == "__main__":
    asyncio.run(main())
