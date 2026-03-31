"""
End-to-end test for food analysis prompts against the LIVE Render backend.

Tests ~225 food descriptions from FOOD_LOG_TEST_PROMPTS.md and FOOD_LOG_EDGE_CASES.md
by calling the analyze-text-stream endpoint via HTTP.

Usage:
    python tests/test_food_prompts_e2e.py [--render] [--limit N]

Requires: SUPABASE_URL, SUPABASE_KEY, TEST_USER_EMAIL, TEST_USER_PASSWORD env vars
          OR a valid SUPABASE_ACCESS_TOKEN env var.
"""

import asyncio
import json
import os
import re
import sys
import time
import httpx

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

RENDER_URL = "https://aifitnesscoach-zqi3.onrender.com"
LOCAL_URL = "http://localhost:8000"

# ── Prompt lists ────────────────────────────────────────────────

TEST_PROMPTS = [
    # === FOOD_LOG_TEST_PROMPTS.md - Breakfast (1-20) ===
    "3 scrambled eggs with toast and orange juice",
    "oatmeal with banana, blueberries and honey",
    "greek yogurt parfait with granola and strawberries",
    "2 slices of avocado toast with a fried egg on top",
    "protein shake with almond milk, peanut butter and banana",
    "pancakes with maple syrup and bacon",
    "smoothie bowl with acai, mixed berries and coconut flakes",
    "bagel with cream cheese and smoked salmon",
    "french toast with powdered sugar and a side of fruit",
    "overnight oats with chia seeds, almonds and maple syrup",
    "egg white omelette with spinach, mushrooms and feta",
    "bowl of cheerios with whole milk and a banana",
    "breakfast burrito with eggs, cheese, beans and salsa",
    "2 waffles with butter and blueberry syrup",
    "cottage cheese with pineapple chunks and walnuts",
    "masala dosa with coconut chutney and sambar",
    "shakshuka with 2 pita breads",
    "croissant with ham and swiss cheese",
    "acai bowl with granola, banana and peanut butter drizzle",
    "4 idlis with coconut chutney",
    # === Lunch (21-45) ===
    "grilled chicken caesar salad with croutons",
    "turkey and avocado sandwich on whole wheat",
    "chipotle bowl with brown rice, chicken, black beans, guac and cheese",
    "sushi roll combo - 2 california rolls and 1 spicy tuna roll",
    "chicken tikka masala with basmati rice and garlic naan",
    "pho with beef, bean sprouts and sriracha",
    "mediterranean wrap with hummus, falafel and tabbouleh",
    "grilled salmon with quinoa, boiled broccoli and a side of greek salad",
    "pad thai with shrimp and a thai iced tea",
    "burger with fries and a coke",
    "chicken quesadilla with sour cream and guacamole",
    "poke bowl with tuna, edamame, avocado and rice",
    "subway footlong turkey sub with chips and water",
    "butter chicken with jeera rice and raita",
    "bibimbap with beef and a fried egg",
    "cobb salad with grilled chicken and ranch dressing",
    "fish tacos with mango salsa and black beans",
    "paneer tikka wrap with mint chutney",
    "ramen with pork belly, soft boiled egg and corn",
    "caprese sandwich with fresh mozzarella, tomato and basil",
    "dal tadka with 3 rotis and pickle",
    "chicken shawarma plate with hummus, rice and salad",
    "tom yum soup with jasmine rice",
    "black bean burger with sweet potato fries",
    "biryani with raita and mirchi ka salan",
    # === Dinner (46-70) ===
    "8oz ribeye steak with mashed potatoes and asparagus",
    "baked salmon with roasted vegetables and brown rice",
    "chicken alfredo pasta with garlic bread",
    "lamb chops with mint sauce, roasted potatoes and green beans",
    "shrimp stir fry with vegetables and white rice",
    "margherita pizza - 3 slices",
    "grilled chicken breast with sweet potato and steamed broccoli",
    "beef tacos with cheese, lettuce, tomato and sour cream",
    "spaghetti bolognese with parmesan cheese",
    "teriyaki chicken with fried rice and miso soup",
    "fish and chips with tartar sauce and coleslaw",
    "chicken parmesan with spaghetti",
    "pork tenderloin with apple sauce and roasted brussels sprouts",
    "vegetable curry with coconut rice",
    "grilled tuna steak with quinoa salad",
    "BBQ ribs with cornbread and mac and cheese",
    "stuffed bell peppers with ground turkey and cheese",
    "lobster tail with butter, corn on the cob and baked potato",
    "eggplant parmesan with side salad",
    "chole bhature with onion salad",
    "thai green curry with chicken and jasmine rice",
    "meatloaf with gravy, mashed potatoes and peas",
    "2 slices of pepperoni pizza with a side of buffalo wings",
    "palak paneer with 2 butter naans",
    "salmon teriyaki bowl with edamame and seaweed salad",
    # === Snacks (71-85) ===
    "apple with 2 tablespoons peanut butter",
    "handful of mixed nuts and dried cranberries",
    "protein bar and a black coffee",
    "hummus with carrot sticks and pita chips",
    "string cheese and a handful of almonds",
    "rice cakes with almond butter and banana slices",
    "trail mix with dark chocolate chips",
    "greek yogurt with a drizzle of honey",
    "beef jerky and an orange",
    "cottage cheese with cucumber and everything bagel seasoning",
    "2 hard boiled eggs with salt and pepper",
    "celery sticks with peanut butter and raisins",
    "a banana and a scoop of whey protein in water",
    "edamame with sea salt",
    "dark chocolate square and a handful of cashews",
    # === Complex / Multi-course (86-100) ===
    "thanksgiving plate - turkey breast, stuffing, cranberry sauce, mashed potatoes, gravy, green bean casserole and a dinner roll",
    "indian thali - dal, paneer, aloo gobi, rice, 2 rotis, raita and papad",
    "sushi dinner - miso soup, edamame, 8 pieces of nigiri and a dragon roll",
    "korean BBQ - bulgogi, kimchi, japchae, steamed rice and 2 banchan sides",
    "mexican feast - chips and guac, 2 carnitas tacos, rice and beans and a horchata",
    "chinese takeout - kung pao chicken, fried rice, 2 spring rolls and wonton soup",
    "brunch - eggs benedict, hash browns, fruit cup and a mimosa",
    "post workout - 2 scoops whey protein with milk, a banana and a bagel with cream cheese",
    "mediterranean spread - grilled chicken, tabbouleh, baba ganoush, pita bread and baklava",
    "south indian meals - sambar rice, rasam, poriyal, curd rice, appalam and pickle",
    "burger meal - double cheeseburger, large fries, large coke and an apple pie",
    "date night - bruschetta appetizer, 8oz filet mignon, caesar salad, garlic mashed potatoes and tiramisu",
    "game day - 8 buffalo wings, nachos with cheese and jalapenos, 2 beers",
    "healthy bowl - grilled chicken, brown rice, black beans, corn, avocado, pico de gallo and lime crema",
    "cheat day - large pepperoni pizza (4 slices), garlic knots, 2 cans of coke and a brownie sundae",
]

EDGE_CASE_PROMPTS = [
    # === Lazy / Ultra-Short (121-135) ===
    "chicken rice broccoli",
    "eggs toast coffee",
    "protein shake banana",
    "rice dal roti",
    "salad chicken",
    "pasta",
    "sandwich",
    "pizza 2 slices",
    "oats milk",
    "steak potatoes",
    "noodles and egg",
    "pb&j",
    "yogurt",
    "apple",
    "just a shake",
    # === Shorthand With Quantities (136-145) ===
    "2 eggs 3 toast butter",
    "rice dal sabzi roti x2",
    "3 chapati with chole",
    "1 scoop whey + milk",
    "6 inch sub turkey",
    "5 momos",
    "2x protein bar",
    "chicken 200g rice 1 cup",
    "4 egg whites 1 whole egg",
    "bowl of cereal",
    # === Misspellings & Typos (11-20) ===
    "chiken brest with rise",
    "scrambeld egs and toest",
    "avacado on sourdogh",
    "spagetti bolognaise",
    "ceaser salad with cruttons",
    "brocoli and chese soup",
    "yoghurt with granolla",
    "penaut butter sandwitch",
    "berrys and cream",
    "teriaki salmon bowel",
    # === Slang / Casual Language (21-30) ===
    "a zinger burger from kfc with a large pepsi",
    "maccas double quarter pounder meal with a sprite",
    "two za slices and a mountain dew",
    "meal prepped chicken and rice x5 containers",
    "dirty bulk - 4 scoops mass gainer with whole milk",
    "anabolic french toast 4 slices",
    # === Quantities & Measurements (31-40) ===
    "200g chicken breast with 1 cup brown rice and 150g broccoli",
    "6oz sirloin steak medium rare",
    "half a pound of ground turkey with pasta",
    "2.5 scoops of whey in 16oz whole milk",
    "about a fistful of almonds",
    "a palm-sized piece of salmon",
    "3/4 cup of oats with 1 tbsp honey",
    "12 piece chicken nuggets",
    "a whole rotisserie chicken",
    "1 liter of orange juice throughout the day",
    # === Regional / Cultural Foods (41-55) ===
    "arepas with shredded beef and black beans",
    "injera with doro wot and misir wot",
    "jollof rice with fried plantain and grilled chicken",
    "pupusas de queso with curtido and salsa roja",
    "poutine with extra cheese curds",
    "pierogi with sour cream and caramelized onions",
    "banh mi with pork belly and pickled daikon",
    "nasi goreng with a fried egg and prawn crackers",
    "tagine with lamb, apricots and couscous",
    "ceviche with tostadas and aguachile",
    "fufu and egusi soup with goat meat",
    "khachapuri with extra egg and butter",
    "mole negro with chicken and corn tortillas",
    "borscht with smetana and black bread",
    # === Indian Regional (56-65) ===
    "pesarattu with ginger chutney and upma",
    "vada pav with green chutney and fried chillies",
    "2 plates of pani puri",
    "mysore masala dosa with filter coffee",
    "hyderabadi dum biryani with mirchi ka salan and raita",
    "fish curry kerala style with appam",
    "rajma chawal with onion salad and pickle",
    "pav bhaji with extra butter",
    "chicken 65 with parotta",
    "thepla with aam ras and chhachh",
    # === Restaurant / Brand Names (66-75) ===
    "grande caramel frappuccino from starbucks with whipped cream",
    "chipotle burrito bowl double chicken no rice extra guac",
    "chick-fil-a spicy deluxe sandwich with waffle fries and lemonade",
    "dominos medium pepperoni pizza thin crust",
    "sweetgreen harvest bowl",
    "shake shack double shackburger with cheese fries",
    "panera bread broccoli cheddar soup in a bread bowl",
    "wingstop 10 piece lemon pepper with ranch and fries",
    "in-n-out double double animal style with fries and a neapolitan shake",
    "trader joes orange chicken with frozen fried rice",
    # === Mixed Meals / Grazing (76-80) ===
    "handful of chips then some leftover pasta then a cookie",
    "picked at the charcuterie board - some cheese, crackers, grapes and prosciutto",
    "tasted while cooking - few spoonfuls of sauce, piece of bread, some cheese",
    "kids leftovers - half a pb&j, some goldfish crackers, apple slices",
    "work potluck - samosa, spring roll, slice of cake, some fruit",
    # === Supplements (81-85) ===
    "5g creatine monohydrate with 2 scoops optimum nutrition gold standard whey in water",
    "BCAA drink during workout plus a banana and granola bar after",
    "meal replacement bar - quest hero chocolate and a black coffee",
    "fairlife protein shake chocolate and a kind bar",
    # === Drinks & Alcohol (86-90) ===
    "2 glasses of red wine with dinner",
    "3 IPAs and a shot of whiskey at the bar",
    "boba tea taro flavor large with tapioca pearls",
    "green smoothie - kale spinach banana mango ginger",
    "mango lassi and a masala chai",
    # === Dietary Restrictions (91-95) ===
    "gluten free pasta with marinara and nutritional yeast",
    "keto plate - bacon cheese burger no bun with side salad",
    "vegan buddha bowl - tofu, sweet potato, kale, tahini dressing, brown rice",
    "whole30 compliant - grilled chicken, roasted sweet potato, sauteed spinach in ghee",
    "carnivore diet - 1lb ground beef and 4 eggs fried in butter",
    # === Multi-Language (101-110) ===
    "2 plate momos with red chutney",
    "tonkotsu ramen with chashu and ajitama",
    "shawarma with toum and pickled turnips",
    "xiao long bao 8 pieces with black vinegar",
    "golgappa 2 plates with meetha pani",
    "kathi roll double egg double chicken",
    "peri peri chicken from nandos half chicken with spicy rice",
    # === Tricky Parsing (111-120) ===
    "fish - not fish and chips just grilled fish",
    "chicken sandwich but i took off the top bun",
    "salad but with a lot of ranch like probably 4 tablespoons",
    "oatmeal but i used heavy cream instead of milk",
    "burrito but i only ate the insides and left the tortilla",
    "had 2 bites of my girlfriend's dessert - it was a chocolate lava cake",
    # === Diet / Fitness Speak (216-225) ===
    "lean bulk meal 3 of 6",
    "high protein low carb - tuna salad no croutons no dressing",
    "cutting meal - tilapia asparagus rice cakes",
    "maintenance calories - steak rice veggies",
]

# ── Validation logic ────────────────────────────────────────────

# Minimum expected total calories for each prompt category
# Foods that are genuinely low-cal (water, gum, etc.) get 0 min
MIN_EXPECTED_CALS = 30  # Most real foods should have > 30 total calories
SUSPICIOUS_PER_ITEM_CAL = 10  # Individual food item below this is suspect


def validate_result(description: str, result: dict) -> dict:
    """Validate a food analysis result. Returns {status, reason, details}."""
    food_items = result.get("food_items", [])
    total_cal = result.get("total_calories", 0)

    # Check if we got any food items
    if not food_items:
        return {"status": "FAIL", "reason": "No food items returned", "total_cal": 0, "items": 0}

    # Check for suspiciously low total calories
    if total_cal < MIN_EXPECTED_CALS and len(food_items) > 0:
        # Allow genuinely low-cal items
        low_cal_keywords = ["water", "gum", "coffee", "tea", "diet", "zero"]
        desc_lower = description.lower()
        if not any(kw in desc_lower for kw in low_cal_keywords):
            return {
                "status": "FAIL",
                "reason": f"Total calories suspiciously low: {total_cal}",
                "total_cal": total_cal,
                "items": len(food_items),
            }

    # Check individual items for absurdly low calories
    bad_items = []
    for item in food_items:
        item_cal = item.get("calories", 0)
        item_name = item.get("name", "Unknown")
        item_weight = item.get("weight_g", 0)

        # Skip genuinely zero-cal items
        if item_cal < SUSPICIOUS_PER_ITEM_CAL and item_weight > 20:
            zero_cal_foods = ["water", "black coffee", "tea", "diet", "zero", "gum",
                              "sparkling", "seltzer", "ice", "lemon", "lime", "vinegar",
                              "mustard", "hot sauce", "spice", "herb", "salt", "pepper",
                              "creatine", "bcaa"]
            if not any(kw in item_name.lower() for kw in zero_cal_foods):
                bad_items.append(f"{item_name}={item_cal}kcal/{item_weight}g")

    if bad_items:
        return {
            "status": "FAIL",
            "reason": f"Items with suspiciously low calories: {', '.join(bad_items[:3])}",
            "total_cal": total_cal,
            "items": len(food_items),
        }

    return {
        "status": "PASS",
        "reason": "",
        "total_cal": total_cal,
        "items": len(food_items),
    }


async def analyze_food(client: httpx.AsyncClient, base_url: str, token: str,
                        user_id: str, description: str) -> dict:
    """Call analyze-text-stream and parse SSE response."""
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    body = {"user_id": user_id, "description": description, "meal_type": "lunch"}

    try:
        async with client.stream(
            "POST", f"{base_url}/nutrition/analyze-text-stream",
            json=body, headers=headers, timeout=60.0
        ) as resp:
            if resp.status_code == 401:
                return {"error": "AUTH_FAILED"}
            if resp.status_code == 429:
                return {"error": "RATE_LIMITED"}
            if resp.status_code != 200:
                return {"error": f"HTTP_{resp.status_code}"}

            result = None
            async for line in resp.aiter_lines():
                if line.startswith("data: "):
                    try:
                        data = json.loads(line[6:])
                        if data.get("type") == "done" or data.get("type") == "result":
                            result = data
                        elif "food_items" in data:
                            result = data
                    except json.JSONDecodeError:
                        pass

            return result or {"error": "NO_DONE_EVENT"}

    except httpx.TimeoutException:
        return {"error": "TIMEOUT"}
    except Exception as e:
        return {"error": str(e)[:80]}


async def get_auth_token(supabase_url: str, supabase_key: str, email: str, password: str) -> tuple:
    """Get a Supabase auth token via email/password sign-in."""
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{supabase_url}/auth/v1/token?grant_type=password",
            json={"email": email, "password": password},
            headers={
                "apikey": supabase_key,
                "Content-Type": "application/json",
            },
            timeout=15.0,
        )
        if resp.status_code == 200:
            data = resp.json()
            return data.get("access_token"), data.get("user", {}).get("id")
        else:
            print(f"Auth failed: {resp.status_code} {resp.text[:200]}")
            return None, None


async def run_tests(base_url: str, token: str, user_id: str, prompts: list,
                     label: str, limit: int = 0, concurrency: int = 3):
    """Run food analysis tests with controlled concurrency."""
    if limit > 0:
        prompts = prompts[:limit]

    results = []
    sem = asyncio.Semaphore(concurrency)
    passed = 0
    failed = 0
    errors = 0

    async def test_one(idx: int, desc: str):
        nonlocal passed, failed, errors
        async with sem:
            # Rate limit: small delay between requests
            await asyncio.sleep(0.5)

            async with httpx.AsyncClient() as client:
                t0 = time.time()
                result = await analyze_food(client, base_url, token, user_id, desc)
                elapsed = int((time.time() - t0) * 1000)

            if "error" in result:
                status = "ERROR"
                reason = result["error"]
                total_cal = 0
                items = 0
                errors += 1
            else:
                v = validate_result(desc, result)
                status = v["status"]
                reason = v["reason"]
                total_cal = v["total_cal"]
                items = v["items"]
                if status == "PASS":
                    passed += 1
                else:
                    failed += 1

            icon = "✅" if status == "PASS" else ("❌" if status == "FAIL" else "⚠️")
            short_desc = desc[:55] + "..." if len(desc) > 55 else desc
            print(f"  {icon} [{idx+1:3d}] {short_desc:<60s} {total_cal:>5d} kcal  {items} items  {elapsed:>5d}ms  {reason}")

            results.append({
                "idx": idx + 1,
                "description": desc,
                "status": status,
                "total_cal": total_cal,
                "items": items,
                "reason": reason,
                "elapsed_ms": elapsed,
            })

    print(f"\n{'='*120}")
    print(f"  {label} — Testing {len(prompts)} prompts against {base_url}")
    print(f"{'='*120}")

    # Run sequentially to avoid rate limiting (10/min endpoint limit)
    for i, desc in enumerate(prompts):
        await test_one(i, desc)
        # Respect rate limit: 10/min = 1 every 6s
        if (i + 1) % 9 == 0:
            print(f"  ⏳ Rate limit pause (10/min)...")
            await asyncio.sleep(12)

    print(f"\n{'='*120}")
    print(f"  RESULTS: {passed} PASS | {failed} FAIL | {errors} ERROR | Total: {len(prompts)}")
    print(f"{'='*120}\n")

    return results


async def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--render", action="store_true", help="Test against Render (default: localhost)")
    parser.add_argument("--limit", type=int, default=0, help="Limit number of prompts per category")
    parser.add_argument("--edge-only", action="store_true", help="Only run edge case prompts")
    parser.add_argument("--main-only", action="store_true", help="Only run main prompts")
    args = parser.parse_args()

    base_url = RENDER_URL if args.render else LOCAL_URL

    # Get auth token
    email = os.environ.get("TEST_USER_EMAIL")
    password = os.environ.get("TEST_USER_PASSWORD")
    token = os.environ.get("SUPABASE_ACCESS_TOKEN")
    user_id = os.environ.get("TEST_USER_ID")

    if not token:
        if not email or not password:
            print("Set TEST_USER_EMAIL + TEST_USER_PASSWORD, or SUPABASE_ACCESS_TOKEN")
            sys.exit(1)
        sb_url = os.environ.get("SUPABASE_URL", "https://hpbzfahijszqmgsybuor.supabase.co")
        sb_key = os.environ.get("SUPABASE_ANON_KEY", os.environ.get("SUPABASE_KEY", ""))
        token, user_id = await get_auth_token(sb_url, sb_key, email, password)
        if not token:
            print("Failed to get auth token")
            sys.exit(1)

    if not user_id:
        user_id = "99dc209b-f6ff-4ba3-887a-875457810415"

    all_results = []

    if not args.edge_only:
        r = await run_tests(base_url, token, user_id, TEST_PROMPTS, "MAIN PROMPTS", args.limit)
        all_results.extend(r)

    if not args.main_only:
        r = await run_tests(base_url, token, user_id, EDGE_CASE_PROMPTS, "EDGE CASE PROMPTS", args.limit)
        all_results.extend(r)

    # Summary table
    pass_count = sum(1 for r in all_results if r["status"] == "PASS")
    fail_count = sum(1 for r in all_results if r["status"] == "FAIL")
    err_count = sum(1 for r in all_results if r["status"] == "ERROR")

    print(f"\n{'='*120}")
    print(f"  FINAL SUMMARY: {pass_count} PASS | {fail_count} FAIL | {err_count} ERROR | Total: {len(all_results)}")
    print(f"{'='*120}")

    if fail_count > 0:
        print(f"\n  FAILED ITEMS:")
        for r in all_results:
            if r["status"] == "FAIL":
                print(f"    ❌ [{r['idx']:3d}] {r['description'][:70]:<72s} {r['total_cal']}kcal  {r['reason']}")

    if err_count > 0:
        print(f"\n  ERROR ITEMS:")
        for r in all_results:
            if r["status"] == "ERROR":
                print(f"    ⚠️  [{r['idx']:3d}] {r['description'][:70]:<72s} {r['reason']}")

    # Save results to JSON
    out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "food_test_results.json")
    with open(out_path, "w") as f:
        json.dump({
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "base_url": base_url,
            "total": len(all_results),
            "passed": pass_count,
            "failed": fail_count,
            "errors": err_count,
            "results": all_results,
        }, f, indent=2)
    print(f"\n  Results saved to: {out_path}")


if __name__ == "__main__":
    asyncio.run(main())
