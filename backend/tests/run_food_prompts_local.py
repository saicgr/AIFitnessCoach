#!/usr/bin/env python3
"""
Local E2E test for food analysis prompts.
Calls the cache service + Gemini enhance pipeline directly (same code path as API).
No auth needed — runs against live Supabase + Gemini.

Usage:
    cd backend && python tests/run_food_prompts_local.py
    cd backend && python tests/run_food_prompts_local.py --limit 5
    cd backend && python tests/run_food_prompts_local.py --edge-only
"""

import asyncio
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Load .env
from dotenv import load_dotenv
load_dotenv()

SUSPICIOUS_PER_ITEM_CAL = 10
MIN_EXPECTED_TOTAL_CAL = 30

# ── All prompts ─────────────────────────────────────────────────

MAIN_PROMPTS = [
    ("B1", "3 scrambled eggs with toast and orange juice"),
    ("B2", "oatmeal with banana, blueberries and honey"),
    ("B3", "greek yogurt parfait with granola and strawberries"),
    ("B4", "2 slices of avocado toast with a fried egg on top"),
    ("B5", "protein shake with almond milk, peanut butter and banana"),
    ("B6", "pancakes with maple syrup and bacon"),
    ("B7", "smoothie bowl with acai, mixed berries and coconut flakes"),
    ("B8", "bagel with cream cheese and smoked salmon"),
    ("B9", "french toast with powdered sugar and a side of fruit"),
    ("B10", "overnight oats with chia seeds, almonds and maple syrup"),
    ("B11", "egg white omelette with spinach, mushrooms and feta"),
    ("B12", "bowl of cheerios with whole milk and a banana"),
    ("B13", "breakfast burrito with eggs, cheese, beans and salsa"),
    ("B14", "2 waffles with butter and blueberry syrup"),
    ("B15", "cottage cheese with pineapple chunks and walnuts"),
    ("B16", "masala dosa with coconut chutney and sambar"),
    ("B17", "shakshuka with 2 pita breads"),
    ("B18", "croissant with ham and swiss cheese"),
    ("B19", "acai bowl with granola, banana and peanut butter drizzle"),
    ("B20", "4 idlis with coconut chutney"),
    ("L21", "grilled chicken caesar salad with croutons"),
    ("L22", "turkey and avocado sandwich on whole wheat"),
    ("L23", "chipotle bowl with brown rice, chicken, black beans, guac and cheese"),
    ("L24", "sushi roll combo - 2 california rolls and 1 spicy tuna roll"),
    ("L25", "chicken tikka masala with basmati rice and garlic naan"),
    ("L26", "pho with beef, bean sprouts and sriracha"),
    ("L27", "mediterranean wrap with hummus, falafel and tabbouleh"),
    ("L28", "grilled salmon with quinoa, boiled broccoli and a side of greek salad"),
    ("L29", "pad thai with shrimp and a thai iced tea"),
    ("L30", "burger with fries and a coke"),
    ("L31", "chicken quesadilla with sour cream and guacamole"),
    ("L32", "poke bowl with tuna, edamame, avocado and rice"),
    ("L33", "subway footlong turkey sub with chips and water"),
    ("L34", "butter chicken with jeera rice and raita"),
    ("L35", "bibimbap with beef and a fried egg"),
    ("L36", "cobb salad with grilled chicken and ranch dressing"),
    ("L37", "fish tacos with mango salsa and black beans"),
    ("L38", "paneer tikka wrap with mint chutney"),
    ("L39", "ramen with pork belly, soft boiled egg and corn"),
    ("L40", "caprese sandwich with fresh mozzarella, tomato and basil"),
    ("L41", "dal tadka with 3 rotis and pickle"),
    ("L42", "chicken shawarma plate with hummus, rice and salad"),
    ("L43", "tom yum soup with jasmine rice"),
    ("L44", "black bean burger with sweet potato fries"),
    ("L45", "biryani with raita and mirchi ka salan"),
    ("D46", "8oz ribeye steak with mashed potatoes and asparagus"),
    ("D47", "baked salmon with roasted vegetables and brown rice"),
    ("D48", "chicken alfredo pasta with garlic bread"),
    ("D49", "lamb chops with mint sauce, roasted potatoes and green beans"),
    ("D50", "shrimp stir fry with vegetables and white rice"),
    ("D51", "margherita pizza - 3 slices"),
    ("D52", "grilled chicken breast with sweet potato and steamed broccoli"),
    ("D53", "beef tacos with cheese, lettuce, tomato and sour cream"),
    ("D54", "spaghetti bolognese with parmesan cheese"),
    ("D55", "teriyaki chicken with fried rice and miso soup"),
    ("D56", "fish and chips with tartar sauce and coleslaw"),
    ("D57", "chicken parmesan with spaghetti"),
    ("D58", "pork tenderloin with apple sauce and roasted brussels sprouts"),
    ("D59", "vegetable curry with coconut rice"),
    ("D60", "grilled tuna steak with quinoa salad"),
    ("D61", "BBQ ribs with cornbread and mac and cheese"),
    ("D62", "stuffed bell peppers with ground turkey and cheese"),
    ("D63", "lobster tail with butter, corn on the cob and baked potato"),
    ("D64", "eggplant parmesan with side salad"),
    ("D65", "chole bhature with onion salad"),
    ("D66", "thai green curry with chicken and jasmine rice"),
    ("D67", "meatloaf with gravy, mashed potatoes and peas"),
    ("D68", "2 slices of pepperoni pizza with a side of buffalo wings"),
    ("D69", "palak paneer with 2 butter naans"),
    ("D70", "salmon teriyaki bowl with edamame and seaweed salad"),
    ("S71", "apple with 2 tablespoons peanut butter"),
    ("S72", "handful of mixed nuts and dried cranberries"),
    ("S73", "protein bar and a black coffee"),
    ("S74", "hummus with carrot sticks and pita chips"),
    ("S75", "string cheese and a handful of almonds"),
    ("S76", "rice cakes with almond butter and banana slices"),
    ("S77", "trail mix with dark chocolate chips"),
    ("S78", "greek yogurt with a drizzle of honey"),
    ("S79", "beef jerky and an orange"),
    ("S80", "cottage cheese with cucumber and everything bagel seasoning"),
    ("S81", "2 hard boiled eggs with salt and pepper"),
    ("S82", "celery sticks with peanut butter and raisins"),
    ("S83", "a banana and a scoop of whey protein in water"),
    ("S84", "edamame with sea salt"),
    ("S85", "dark chocolate square and a handful of cashews"),
    ("C86", "thanksgiving plate - turkey breast, stuffing, cranberry sauce, mashed potatoes, gravy, green bean casserole and a dinner roll"),
    ("C87", "indian thali - dal, paneer, aloo gobi, rice, 2 rotis, raita and papad"),
    ("C88", "sushi dinner - miso soup, edamame, 8 pieces of nigiri and a dragon roll"),
    ("C89", "korean BBQ - bulgogi, kimchi, japchae, steamed rice and 2 banchan sides"),
    ("C90", "mexican feast - chips and guac, 2 carnitas tacos, rice and beans and a horchata"),
    ("C91", "chinese takeout - kung pao chicken, fried rice, 2 spring rolls and wonton soup"),
    ("C92", "brunch - eggs benedict, hash browns, fruit cup and a mimosa"),
    ("C93", "post workout - 2 scoops whey protein with milk, a banana and a bagel with cream cheese"),
    ("C94", "mediterranean spread - grilled chicken, tabbouleh, baba ganoush, pita bread and baklava"),
    ("C95", "south indian meals - sambar rice, rasam, poriyal, curd rice, appalam and pickle"),
    ("C96", "burger meal - double cheeseburger, large fries, large coke and an apple pie"),
    ("C97", "date night - bruschetta appetizer, 8oz filet mignon, caesar salad, garlic mashed potatoes and tiramisu"),
    ("C98", "game day - 8 buffalo wings, nachos with cheese and jalapenos, 2 beers"),
    ("C99", "healthy bowl - grilled chicken, brown rice, black beans, corn, avocado, pico de gallo and lime crema"),
    ("C100", "cheat day - large pepperoni pizza (4 slices), garlic knots, 2 cans of coke and a brownie sundae"),
]

EDGE_PROMPTS = [
    ("E121", "chicken rice broccoli"),
    ("E122", "eggs toast coffee"),
    ("E123", "protein shake banana"),
    ("E124", "rice dal roti"),
    ("E125", "salad chicken"),
    ("E126", "pasta"),
    ("E127", "sandwich"),
    ("E128", "pizza 2 slices"),
    ("E129", "oats milk"),
    ("E130", "steak potatoes"),
    ("E131", "noodles and egg"),
    ("E132", "pb&j"),
    ("E133", "yogurt"),
    ("E134", "apple"),
    ("E135", "just a shake"),
    ("E136", "2 eggs 3 toast butter"),
    ("E137", "rice dal sabzi roti x2"),
    ("E138", "3 chapati with chole"),
    ("E139", "1 scoop whey + milk"),
    ("E140", "6 inch sub turkey"),
    ("E141", "5 momos"),
    ("E142", "2x protein bar"),
    ("E143", "chicken 200g rice 1 cup"),
    ("E144", "4 egg whites 1 whole egg"),
    ("E145", "bowl of cereal"),
    ("T11", "chiken brest with rise"),
    ("T12", "scrambeld egs and toest"),
    ("T13", "avacado on sourdogh"),
    ("T14", "spagetti bolognaise"),
    ("T15", "ceaser salad with cruttons"),
    ("T16", "brocoli and chese soup"),
    ("T17", "yoghurt with granolla"),
    ("T18", "penaut butter sandwitch"),
    ("T19", "berrys and cream"),
    ("T20", "teriaki salmon bowel"),
    ("SL21", "a zinger burger from kfc with a large pepsi"),
    ("SL22", "maccas double quarter pounder meal with a sprite"),
    ("SL23", "two za slices and a mountain dew"),
    ("SL24", "meal prepped chicken and rice x5 containers"),
    ("SL25", "dirty bulk - 4 scoops mass gainer with whole milk"),
    ("SL26", "anabolic french toast 4 slices"),
    ("Q31", "200g chicken breast with 1 cup brown rice and 150g broccoli"),
    ("Q32", "6oz sirloin steak medium rare"),
    ("Q33", "half a pound of ground turkey with pasta"),
    ("Q34", "2.5 scoops of whey in 16oz whole milk"),
    ("Q35", "about a fistful of almonds"),
    ("Q36", "a palm-sized piece of salmon"),
    ("Q37", "3/4 cup of oats with 1 tbsp honey"),
    ("Q38", "12 piece chicken nuggets"),
    ("Q39", "a whole rotisserie chicken"),
    ("Q40", "1 liter of orange juice throughout the day"),
    ("R41", "arepas with shredded beef and black beans"),
    ("R42", "injera with doro wot and misir wot"),
    ("R43", "jollof rice with fried plantain and grilled chicken"),
    ("R44", "pupusas de queso with curtido and salsa roja"),
    ("R45", "poutine with extra cheese curds"),
    ("R46", "pierogi with sour cream and caramelized onions"),
    ("R47", "banh mi with pork belly and pickled daikon"),
    ("R48", "nasi goreng with a fried egg and prawn crackers"),
    ("R49", "tagine with lamb, apricots and couscous"),
    ("R50", "ceviche with tostadas and aguachile"),
    ("R51", "fufu and egusi soup with goat meat"),
    ("R52", "khachapuri with extra egg and butter"),
    ("R53", "mole negro with chicken and corn tortillas"),
    ("R54", "borscht with smetana and black bread"),
    ("I56", "pesarattu with ginger chutney and upma"),
    ("I57", "vada pav with green chutney and fried chillies"),
    ("I58", "2 plates of pani puri"),
    ("I59", "mysore masala dosa with filter coffee"),
    ("I60", "hyderabadi dum biryani with mirchi ka salan and raita"),
    ("I61", "fish curry kerala style with appam"),
    ("I62", "rajma chawal with onion salad and pickle"),
    ("I63", "pav bhaji with extra butter"),
    ("I64", "chicken 65 with parotta"),
    ("I65", "thepla with aam ras and chhachh"),
    ("BR66", "grande caramel frappuccino from starbucks with whipped cream"),
    ("BR67", "chipotle burrito bowl double chicken no rice extra guac"),
    ("BR68", "chick-fil-a spicy deluxe sandwich with waffle fries and lemonade"),
    ("BR69", "dominos medium pepperoni pizza thin crust"),
    ("BR70", "sweetgreen harvest bowl"),
    ("BR71", "shake shack double shackburger with cheese fries"),
    ("BR72", "panera bread broccoli cheddar soup in a bread bowl"),
    ("BR73", "wingstop 10 piece lemon pepper with ranch and fries"),
    ("BR74", "in-n-out double double animal style with fries and a neapolitan shake"),
    ("BR75", "trader joes orange chicken with frozen fried rice"),
    ("MX76", "handful of chips then some leftover pasta then a cookie"),
    ("MX77", "picked at the charcuterie board - some cheese, crackers, grapes and prosciutto"),
    ("MX78", "tasted while cooking - few spoonfuls of sauce, piece of bread, some cheese"),
    ("MX79", "kids leftovers - half a pb&j, some goldfish crackers, apple slices"),
    ("MX80", "work potluck - samosa, spring roll, slice of cake, some fruit"),
    ("SP81", "5g creatine monohydrate with 2 scoops optimum nutrition gold standard whey in water"),
    ("SP82", "BCAA drink during workout plus a banana and granola bar after"),
    ("SP83", "meal replacement bar - quest hero chocolate and a black coffee"),
    ("SP84", "fairlife protein shake chocolate and a kind bar"),
    ("DR86", "2 glasses of red wine with dinner"),
    ("DR87", "3 IPAs and a shot of whiskey at the bar"),
    ("DR88", "boba tea taro flavor large with tapioca pearls"),
    ("DR89", "green smoothie - kale spinach banana mango ginger"),
    ("DR90", "mango lassi and a masala chai"),
    ("DT91", "gluten free pasta with marinara and nutritional yeast"),
    ("DT92", "keto plate - bacon cheese burger no bun with side salad"),
    ("DT93", "vegan buddha bowl - tofu, sweet potato, kale, tahini dressing, brown rice"),
    ("DT94", "whole30 compliant - grilled chicken, roasted sweet potato, sauteed spinach in ghee"),
    ("DT95", "carnivore diet - 1lb ground beef and 4 eggs fried in butter"),
    ("ML101", "2 plate momos with red chutney"),
    ("ML102", "tonkotsu ramen with chashu and ajitama"),
    ("ML103", "shawarma with toum and pickled turnips"),
    ("ML104", "xiao long bao 8 pieces with black vinegar"),
    ("ML105", "golgappa 2 plates with meetha pani"),
    ("ML106", "kathi roll double egg double chicken"),
    ("ML107", "peri peri chicken from nandos half chicken with spicy rice"),
    ("TP111", "fish - not fish and chips just grilled fish"),
    ("TP112", "chicken sandwich but i took off the top bun"),
    ("TP113", "salad but with a lot of ranch like probably 4 tablespoons"),
    ("TP114", "oatmeal but i used heavy cream instead of milk"),
    ("TP115", "burrito but i only ate the insides and left the tortilla"),
    ("TP116", "had 2 bites of my girlfriend's dessert - it was a chocolate lava cake"),
    ("FS216", "lean bulk meal 3 of 6"),
    ("FS217", "high protein low carb - tuna salad no croutons no dressing"),
    ("FS218", "cutting meal - tilapia asparagus rice cakes"),
    ("FS219", "maintenance calories - steak rice veggies"),
]


def validate_result(desc: str, result: dict) -> dict:
    """Validate a food analysis result."""
    food_items = result.get("food_items", [])
    total_cal = result.get("total_calories", 0) or 0

    if not food_items:
        return {"status": "FAIL", "reason": "No food items", "total_cal": 0, "items": 0}

    # Allow genuinely low-cal items
    low_cal_keywords = ["water", "gum", "coffee black", "tea plain", "diet soda",
                         "creatine", "bcaa", "zero cal"]
    desc_lower = desc.lower()
    is_low_cal_food = any(kw in desc_lower for kw in low_cal_keywords)

    if total_cal < MIN_EXPECTED_TOTAL_CAL and not is_low_cal_food:
        return {
            "status": "FAIL",
            "reason": f"Total cal too low: {total_cal}",
            "total_cal": total_cal,
            "items": len(food_items),
        }

    # Check individual items
    bad_items = []
    for item in food_items:
        item_cal = item.get("calories", 0) or 0
        item_name = item.get("name", "?")
        item_weight = item.get("weight_g", 0) or 0

        if item_cal < SUSPICIOUS_PER_ITEM_CAL and item_weight > 20:
            skip_names = ["water", "coffee", "tea", "diet", "zero", "gum", "ice",
                          "lemon", "lime", "vinegar", "mustard", "hot sauce",
                          "salt", "pepper", "creatine", "bcaa", "spice", "herb",
                          "sriracha", "soy sauce", "pickle", "chutney", "salsa",
                          "curtido", "raita", "sambar"]
            if not any(kw in item_name.lower() for kw in skip_names):
                bad_items.append(f"{item_name}={item_cal}kcal/{item_weight}g")

    if bad_items:
        return {
            "status": "FAIL",
            "reason": f"Low-cal items: {', '.join(bad_items[:3])}",
            "total_cal": total_cal,
            "items": len(food_items),
        }

    return {"status": "PASS", "reason": "", "total_cal": total_cal, "items": len(food_items)}


async def analyze_one(cache_svc, desc: str) -> dict:
    """Call the cache service analyze_food (same path as API endpoint)."""
    try:
        result = await asyncio.wait_for(
            cache_svc.analyze_food(
                description=desc,
                user_goals=["muscle_gain"],
                nutrition_targets={"daily_calorie_target": 2500, "daily_protein_target_g": 150},
                meal_type="lunch",
            ),
            timeout=45.0,
        )
        return result
    except asyncio.TimeoutError:
        return {"error": "TIMEOUT"}
    except Exception as e:
        return {"error": str(e)[:120]}


async def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--edge-only", action="store_true")
    parser.add_argument("--main-only", action="store_true")
    args = parser.parse_args()

    # Initialize services
    from services.food_analysis_cache_service import get_food_analysis_cache_service
    cache_svc = get_food_analysis_cache_service()

    prompts_to_run = []
    if not args.edge_only:
        prompts_to_run.extend(MAIN_PROMPTS)
    if not args.main_only:
        prompts_to_run.extend(EDGE_PROMPTS)
    if args.limit > 0:
        prompts_to_run = prompts_to_run[:args.limit]

    passed = 0
    failed = 0
    errors = 0
    all_results = []

    print(f"\n{'='*130}")
    print(f"  FOOD ANALYSIS E2E TEST — {len(prompts_to_run)} prompts")
    print(f"{'='*130}")
    print(f"  {'ID':<8s} {'Status':<6s} {'Cal':>6s} {'Items':>5s} {'Time':>7s}  {'Description':<60s} {'Reason'}")
    print(f"  {'-'*8} {'-'*6} {'-'*6} {'-'*5} {'-'*7}  {'-'*60} {'-'*30}")

    for tag, desc in prompts_to_run:
        t0 = time.time()
        result = await analyze_one(cache_svc, desc)
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

        icon = "PASS" if status == "PASS" else ("FAIL" if status == "FAIL" else "ERR ")
        short_desc = desc[:58] + ".." if len(desc) > 58 else desc
        print(f"  {tag:<8s} {icon:<6s} {total_cal:>6d} {items:>5d} {elapsed:>6d}ms  {short_desc:<60s} {reason}")

        all_results.append({
            "id": tag, "description": desc, "status": status,
            "total_cal": total_cal, "items": items, "reason": reason,
            "elapsed_ms": elapsed,
        })

    # Summary
    print(f"\n{'='*130}")
    print(f"  RESULTS: {passed} PASS  |  {failed} FAIL  |  {errors} ERROR  |  Total: {len(prompts_to_run)}")
    pct = (passed / len(prompts_to_run) * 100) if prompts_to_run else 0
    print(f"  Pass rate: {pct:.1f}%")
    print(f"{'='*130}")

    if failed > 0:
        print(f"\n  FAILED ITEMS:")
        for r in all_results:
            if r["status"] == "FAIL":
                print(f"    {r['id']:<8s} {r['total_cal']:>5d} kcal  {r['description'][:70]:<72s}  {r['reason']}")

    if errors > 0:
        print(f"\n  ERROR ITEMS:")
        for r in all_results:
            if r["status"] == "ERROR":
                print(f"    {r['id']:<8s} {r['description'][:70]:<72s}  {r['reason']}")

    # Save
    out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "food_test_results.json")
    with open(out_path, "w") as f:
        json.dump({
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "total": len(all_results), "passed": passed, "failed": failed, "errors": errors,
            "pass_rate": f"{pct:.1f}%",
            "results": all_results,
        }, f, indent=2)
    print(f"\n  Results saved to: {out_path}\n")


if __name__ == "__main__":
    asyncio.run(main())
