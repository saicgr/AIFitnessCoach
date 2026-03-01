-- ============================================================================
-- Migration 277: Add restaurant_name, food_category, default_count
-- Generated: 2026-02-28
--
-- Adds three new columns:
--   restaurant_name: Clean display name of the restaurant chain (e.g. "McDonald's")
--   food_category:   Food type category (e.g. "burgers", "drinks", "breakfast")
--   default_count:   Default number of pieces per serving (e.g. 10 for 10pc nuggets)
--
-- Populates restaurant_name via CASE on source column (domain → chain name)
-- Populates food_category via regex on display_name (keyword matching)
-- Populates default_count via ratio of serving_g / weight_per_piece_g
-- ============================================================================

-- ── Step 1: Add columns ─────────────────────────────────────────────

ALTER TABLE food_nutrition_overrides
  ADD COLUMN IF NOT EXISTS restaurant_name TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS food_category TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS default_count INTEGER DEFAULT 1;

-- ── Step 2: Indexes ─────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_food_overrides_restaurant
  ON food_nutrition_overrides (restaurant_name)
  WHERE restaurant_name IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_food_overrides_category
  ON food_nutrition_overrides (food_category)
  WHERE food_category IS NOT NULL;

-- ── Step 3: Populate restaurant_name from source ────────────────────

UPDATE food_nutrition_overrides
SET restaurant_name = CASE source
  -- Fast food / QSR
  WHEN 'mcdonalds.com' THEN 'McDonald''s'
  WHEN 'tacobell.com' THEN 'Taco Bell'
  WHEN 'chick-fil-a.com' THEN 'Chick-fil-A'
  WHEN 'starbucks.com' THEN 'Starbucks'
  WHEN 'wendys.com' THEN 'Wendy''s'
  WHEN 'bk.com' THEN 'Burger King'
  WHEN 'subnet.com' THEN 'Subway'
  WHEN 'dunkindonuts.com' THEN 'Dunkin'''
  WHEN 'dominos.com' THEN 'Domino''s'
  WHEN 'popeyes.com' THEN 'Popeyes'
  WHEN 'pizzahut.com' THEN 'Pizza Hut'
  WHEN 'kfc.com' THEN 'KFC'
  WHEN 'chipotle.com' THEN 'Chipotle'
  WHEN 'sonicdrivein.com' THEN 'Sonic'
  WHEN 'panerabread.com' THEN 'Panera Bread'
  WHEN 'jackinthebox.com' THEN 'Jack in the Box'
  WHEN 'whataburger.com' THEN 'Whataburger'
  WHEN 'pandaexpress.com' THEN 'Panda Express'
  WHEN 'panda_express_official' THEN 'Panda Express'
  WHEN 'fiveguys.com' THEN 'Five Guys'
  WHEN 'wingstop.com' THEN 'Wingstop'
  WHEN 'zaxbys.com' THEN 'Zaxby''s'
  WHEN 'littlecaesars.com' THEN 'Little Caesars'
  WHEN 'jimmyjohns.com' THEN 'Jimmy John''s'
  WHEN 'jerseymikes.com' THEN 'Jersey Mike''s'
  WHEN 'arbys.com' THEN 'Arby''s'
  WHEN 'hardees.com' THEN 'Hardee''s'
  WHEN 'culvers.com' THEN 'Culver''s'
  WHEN 'firehousesubs.com' THEN 'Firehouse Subs'
  WHEN 'shakeshack.com' THEN 'Shake Shack'
  WHEN 'in-n-out.com' THEN 'In-N-Out Burger'
  WHEN 'noodles.com' THEN 'Noodles & Company'
  WHEN 'wafflehouse.com' THEN 'Waffle House'
  WHEN 'crumblcookies.com' THEN 'Crumbl Cookies'
  WHEN 'tropicalsmoothiecafe.com' THEN 'Tropical Smoothie Cafe'
  WHEN 'portillos.com' THEN 'Portillo''s'
  WHEN 'steaknshake.com' THEN 'Steak ''n Shake'
  WHEN 'steak_n_shake_official' THEN 'Steak ''n Shake'
  WHEN 'churchs.com' THEN 'Church''s Chicken'
  WHEN 'elpolloloco.com' THEN 'El Pollo Loco'
  WHEN 'deltaco.com' THEN 'Del Taco'
  WHEN 'checkersandrallys.com' THEN 'Checkers/Rally''s'
  WHEN 'whitecastle.com' THEN 'White Castle'
  WHEN 'cookout.com' THEN 'Cook Out'
  WHEN 'bojangles.com' THEN 'Bojangles'
  WHEN 'captainds.com' THEN 'Captain D''s'
  WHEN 'ljsilvers.com' THEN 'Long John Silver''s'
  WHEN 'jollibeefoods.com' THEN 'Jollibee'

  -- Pizza chains
  WHEN 'papajohns.com' THEN 'Papa John''s'
  WHEN 'papamurphys.com' THEN 'Papa Murphy''s'
  WHEN 'marcos.com' THEN 'Marco''s Pizza'
  WHEN 'modpizza.com' THEN 'MOD Pizza'
  WHEN 'blazepizza.com' THEN 'Blaze Pizza'

  -- Mexican / Southwest
  WHEN 'moes.com' THEN 'Moe''s Southwest Grill'
  WHEN 'qdoba.com' THEN 'Qdoba'
  WHEN 'bajafresh.com' THEN 'Baja Fresh'

  -- Asian
  WHEN 'peiwei.com' THEN 'Pei Wei'
  WHEN 'pfchangs.com' THEN 'P.F. Chang''s'
  WHEN 'teriyakimadness.com' THEN 'Teriyaki Madness'
  WHEN 'sarkujapan.com' THEN 'Sarku Japan'
  WHEN 'yoshinoyaamerica.com' THEN 'Yoshinoya'
  WHEN 'thehalalguys.com' THEN 'The Halal Guys'

  -- Casual dining
  WHEN 'chilis.com' THEN 'Chili''s'
  WHEN 'applebees.com' THEN 'Applebee''s'
  WHEN 'olivegarden.com' THEN 'Olive Garden'
  WHEN 'buffalowildwings.com' THEN 'Buffalo Wild Wings'
  WHEN 'buffalo_wild_wings_official' THEN 'Buffalo Wild Wings'
  WHEN 'redrobin.com' THEN 'Red Robin'
  WHEN 'red_robin_official' THEN 'Red Robin'
  WHEN 'ihop.com' THEN 'IHOP'
  WHEN 'dennys.com' THEN 'Denny''s'
  WHEN 'crackerbarrel.com' THEN 'Cracker Barrel'
  WHEN 'outback.com' THEN 'Outback Steakhouse'
  WHEN 'redlobster.com' THEN 'Red Lobster'
  WHEN 'texasroadhouse.com' THEN 'Texas Roadhouse'
  WHEN 'tgifridays.com' THEN 'TGI Friday''s'
  WHEN 'thecheesecakefactory.com' THEN 'The Cheesecake Factory'
  WHEN 'goldencorral.com' THEN 'Golden Corral'
  WHEN 'bobevans.com' THEN 'Bob Evans'
  WHEN 'bob_evans_official' THEN 'Bob Evans'
  WHEN 'perkinsrestaurants.com' THEN 'Perkins'
  WHEN 'benihana.com' THEN 'Benihana'
  WHEN 'villageinn.com' THEN 'Village Inn'
  WHEN 'fazolis.com' THEN 'Fazoli''s'
  WHEN 'potbelly.com' THEN 'Potbelly'
  WHEN 'mcalistersdeli.com' THEN 'McAlister''s Deli'
  WHEN 'jasonsdeli.com' THEN 'Jason''s Deli'

  -- Healthy / bowls
  WHEN 'sweetgreen.com' THEN 'Sweetgreen'
  WHEN 'cava.com' THEN 'CAVA'
  WHEN 'wabagrill.com' THEN 'Waba Grill'

  -- Coffee & drinks
  WHEN 'dutchbros.com' THEN 'Dutch Bros'
  WHEN 'timhortons.com' THEN 'Tim Hortons'
  WHEN 'cariboucoffee.com' THEN 'Caribou Coffee'
  WHEN 'jamba.com' THEN 'Jamba'
  WHEN 'smoothieking.com' THEN 'Smoothie King'
  WHEN 'kung_fu_tea_estimated' THEN 'Kung Fu Tea'

  -- Bakery / desserts
  WHEN 'krispykreme.com' THEN 'Krispy Kreme'
  WHEN 'baskinrobbins.com' THEN 'Baskin-Robbins'
  WHEN 'coldstonecreamery.com' THEN 'Cold Stone Creamery'
  WHEN 'dairyqueen.com' THEN 'Dairy Queen'
  WHEN 'auntieannes.com' THEN 'Auntie Anne''s'
  WHEN 'cinnabon.com' THEN 'Cinnabon'
  WHEN 'wetzels.com' THEN 'Wetzel''s Pretzels'
  WHEN 'insomniacookies.com' THEN 'Insomnia Cookies'
  WHEN 'nothingbundtcakes.com' THEN 'Nothing Bundt Cakes'

  -- Generic / non-restaurant sources → NULL
  ELSE NULL
END
WHERE restaurant_name IS NULL;


-- ── Step 4: Populate food_category from display_name ────────────────
-- Priority-ordered CASE: first match wins.
-- Uses PostgreSQL ~* (case-insensitive regex) with \m \M word boundaries.

UPDATE food_nutrition_overrides
SET food_category = CASE
  -- Sauces & condiments (check first - very specific)
  WHEN lower(display_name) ~ '(sauce|dressing|dip |ranch|ketchup|mustard|mayo|gravy|syrup|guacamole|salsa|queso|aioli|vinaigrette)'
    THEN 'sauces'

  -- Drinks & beverages
  WHEN lower(display_name) ~ '(shake |milkshake|smoothie|latte|coffee|soda| tea |lemonade|refresher|frappe|frappuccino|macchiato|mocha|cappuccino|espresso|americano|cold brew|iced tea|hot chocolate|cooler|colada|juice|slush|float|horchata|agua fresca|coca.cola|sprite|fanta|dr.pepper|limeade|arnold palmer)'
    THEN 'drinks'

  -- Breakfast items
  WHEN lower(display_name) ~ '(pancake|waffle|mcmuffin|mcgriddle|omelette|omelet|hash.brown|french toast|breakfast|biscuit.*egg|egg.*biscuit|scramble|croissant.*egg|egg.*croissant|morning|croissan)'
    THEN 'breakfast'

  -- Pizza
  WHEN lower(display_name) ~ '(pizza|calzone|stromboli)'
    THEN 'pizza'

  -- Burgers
  WHEN lower(display_name) ~ '(burger|whopper|big mac|quarter pounder|baconator|steakburger|smashburger|impossible burger|beyond burger|double.*cheese.*burger|triple.*burger)'
    THEN 'burgers'

  -- Mexican
  WHEN lower(display_name) ~ '(taco|burrito|quesadilla|nacho|enchilada|chalupa|gordita|tostada|crunchwrap|mexican pizza|chimichanga|fajita|carnitas|barbacoa|al pastor|elote)'
    THEN 'mexican'

  -- Asian
  WHEN lower(display_name) ~ '(fried rice|lo mein|chow mein|teriyaki|orange chicken|gyoza|kung pao|general tso|egg roll|spring roll|wonton|dumpling|pho|ramen|pad thai|bibimbap|tempura|edamame|miso|sushi|poke|bao)'
    THEN 'asian'

  -- Indian
  WHEN lower(display_name) ~ '(biryani|curry|dosa|naan|paneer|tandoori|masala|tikka|dal |samosa|pakora|idli|uttapam|paratha|roti |chapati|vindaloo|korma|pulao|keema|gosht|raita|chutney|lassi|gulab)'
    THEN 'indian'

  -- Sandwiches & subs
  WHEN lower(display_name) ~ '(sandwich|sub |hoagie|wrap|panini|club |melt |po.boy|cheesesteak|philly|grinder|hero )'
    THEN 'sandwiches'

  -- Chicken items
  WHEN lower(display_name) ~ '(nugget|chicken|wing |wings|tender|strip |strips|breast|thigh|drumstick|popcorn chicken|boneless)'
    THEN 'chicken'

  -- Seafood
  WHEN lower(display_name) ~ '(fish|shrimp|lobster|salmon|crab|clam|oyster|tilapia|calamari|scallop|cod |crawfish|crayfish|prawn|seafood)'
    THEN 'seafood'

  -- Pasta
  WHEN lower(display_name) ~ '(pasta|spaghetti|alfredo|mac.*cheese|macaroni|lasagna|fettuccine|penne|rigatoni|linguine|ravioli|tortellini|ziti|carbonara)'
    THEN 'pasta'

  -- Salads
  WHEN lower(display_name) ~ '(salad|caesar|cobb|garden.*mix|power.bowl|harvest.bowl)'
    THEN 'salads'

  -- Soups
  WHEN lower(display_name) ~ '(soup|chili |chowder|stew|bisque|gumbo|pozole)'
    THEN 'soups'

  -- Steak & BBQ
  WHEN lower(display_name) ~ '(steak|ribs|brisket|bbq|pulled pork|pot roast|prime rib|sirloin|ribeye|filet mignon|tri.tip)'
    THEN 'steak'

  -- Desserts
  WHEN lower(display_name) ~ '(cookie|cake|pie |brownie|cheesecake|donut|doughnut|sundae|ice cream|gelato|frozen yogurt|cupcake|cinnamon roll|churro|cobbler|parfait|fudge|truffle|bundt|macaron|muffin|scone)'
    THEN 'desserts'

  -- Sides
  WHEN lower(display_name) ~ '(fries|french fry|onion ring|coleslaw|mashed potato|corn |rice |bread |biscuit|hush pupp|tater tot|loaded potato|baked potato|sweet potato|cole slaw|green bean|broccoli|applesauce|mac & cheese)'
    THEN 'sides'

  -- Snacks
  WHEN lower(display_name) ~ '(pretzel|mozzarella stick|cheese.curd|jalapeno popper|loaded fry|cheese fry|corn dog|funnel cake)'
    THEN 'snacks'

  -- Staples (generic whole foods)
  WHEN lower(display_name) ~ '(^egg |^eggs |^oat|^milk |^yogurt|^banana|^apple |^rice$|^bread$|^toast$)'
    THEN 'staples'

  -- Fallback
  ELSE 'other'
END
WHERE food_category IS NULL;


-- ── Step 5: Fix remaining 'other' items with more specific patterns ─

UPDATE food_nutrition_overrides
SET food_category = CASE
  WHEN lower(display_name) ~ '(pie$|pie\)|blizzard|frosty|turnover|flurry|mcflurry|cone$|cone\)|bundt|cinnamon roll|cinnabon)' THEN 'desserts'
  WHEN lower(display_name) ~ '(double.double|animal style|smash|steakburger|mcdouble|cheeseburger)' THEN 'burgers'
  WHEN lower(display_name) ~ '(oatmeal|sausage link|sausage patty|bacon.*egg|egg.*bacon)' THEN 'breakfast'
  WHEN lower(display_name) ~ '(hot dog|corn dog|cheese stick|cheese curd|pretzel)' THEN 'snacks'
  WHEN lower(display_name) ~ '(meatball|italian beef|roast beef|club$|club\)|french dip)' THEN 'sandwiches'
  WHEN lower(display_name) ~ '(^[a-z ]*tortilla$|baked beans|collard|green beans|jalapeño poppers|coleslaw|potato salad)' THEN 'sides'
  WHEN lower(display_name) ~ '(crunch bowl|power bowl|grain bowl|poke bowl|teriyaki bowl|rice bowl)' THEN 'asian'
  ELSE food_category
END
WHERE food_category = 'other';


-- ── Step 6: Populate default_count ──────────────────────────────────
-- Count = serving_g / weight_per_piece_g, rounded to nearest integer.
-- Most items are count=1 (one burger, one drink). Multi-piece items
-- like nuggets (10pc), wings (12ct), hash browns (6pc) get higher counts.
-- Also backfill weight_per_piece_g from serving_g where missing.

UPDATE food_nutrition_overrides
SET default_weight_per_piece_g = default_serving_g
WHERE default_weight_per_piece_g IS NULL
  AND default_serving_g IS NOT NULL;

UPDATE food_nutrition_overrides
SET default_count = CASE
  WHEN default_weight_per_piece_g IS NULL OR default_weight_per_piece_g = 0 THEN 1
  WHEN default_serving_g IS NULL OR default_serving_g = 0 THEN 1
  WHEN default_serving_g < default_weight_per_piece_g THEN 1
  ELSE GREATEST(1, ROUND(default_serving_g / default_weight_per_piece_g))
END;
