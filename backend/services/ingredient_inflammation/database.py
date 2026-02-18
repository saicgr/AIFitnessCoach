"""
Curated ingredient inflammation database (~400 entries).

Each entry maps an ingredient name to its inflammation score (1-10),
category, reason, additive status, and aliases.

Score convention:
  1-2 = highly anti-inflammatory
  3-4 = anti-inflammatory
  5-6 = neutral
  7-8 = moderately inflammatory
  9-10 = highly inflammatory

This module also builds an alias index at import time for O(1) lookups.
"""

from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass


@dataclass(frozen=True)
class IngredientRecord:
    score: int           # 1 (anti-inflammatory) to 10 (highly inflammatory)
    category: str        # matches IngredientCategory enum values
    reason: str          # human-readable explanation
    is_additive: bool    # True for preservatives, colorings, emulsifiers
    aliases: tuple       # alternate names (stored as tuple for hashability)


# ═══════════════════════════════════════════════════════════════════════════
# CURATED DATABASE
# ═══════════════════════════════════════════════════════════════════════════

INGREDIENT_DATABASE: Dict[str, IngredientRecord] = {

    # ── Sweeteners (30) ───────────────────────────────────────────────────

    "sugar": IngredientRecord(
        score=9, category="highly_inflammatory",
        reason="Refined sugar triggers inflammatory cytokines and insulin spikes",
        is_additive=False, aliases=("cane sugar", "granulated sugar", "white sugar", "sucrose")),
    "high fructose corn syrup": IngredientRecord(
        score=10, category="highly_inflammatory",
        reason="HFCS promotes liver inflammation and metabolic dysfunction",
        is_additive=False, aliases=("hfcs", "corn syrup high fructose", "hfcs-55", "hfcs-42")),
    "corn syrup": IngredientRecord(
        score=9, category="highly_inflammatory",
        reason="Concentrated glucose syrup promotes insulin resistance",
        is_additive=False, aliases=("corn syrup solids", "glucose syrup")),
    "dextrose": IngredientRecord(
        score=8, category="inflammatory",
        reason="Simple sugar that spikes blood glucose",
        is_additive=False, aliases=("d-glucose",)),
    "fructose": IngredientRecord(
        score=8, category="inflammatory",
        reason="Excess fructose promotes liver fat accumulation and inflammation",
        is_additive=False, aliases=("crystalline fructose",)),
    "maltose": IngredientRecord(
        score=8, category="inflammatory",
        reason="Disaccharide with high glycemic impact",
        is_additive=False, aliases=("malt sugar",)),
    "maltodextrin": IngredientRecord(
        score=8, category="inflammatory",
        reason="High glycemic index carbohydrate that spikes blood sugar",
        is_additive=True, aliases=("maltodextrine",)),
    "brown sugar": IngredientRecord(
        score=8, category="inflammatory",
        reason="Essentially white sugar with molasses; similarly inflammatory",
        is_additive=False, aliases=("light brown sugar", "dark brown sugar")),
    "powdered sugar": IngredientRecord(
        score=8, category="inflammatory",
        reason="Finely ground sugar with cornstarch",
        is_additive=False, aliases=("confectioners sugar", "icing sugar")),
    "invert sugar": IngredientRecord(
        score=8, category="inflammatory",
        reason="Hydrolyzed sucrose, equally inflammatory as regular sugar",
        is_additive=False, aliases=("inverted sugar", "invert syrup")),
    "agave nectar": IngredientRecord(
        score=7, category="inflammatory",
        reason="Very high in fructose despite natural marketing",
        is_additive=False, aliases=("agave syrup", "agave")),
    "honey": IngredientRecord(
        score=6, category="neutral",
        reason="Contains some antioxidants but still high in sugar",
        is_additive=False, aliases=("raw honey", "organic honey")),
    "maple syrup": IngredientRecord(
        score=6, category="neutral",
        reason="Contains some minerals and antioxidants but high sugar content",
        is_additive=False, aliases=("pure maple syrup",)),
    "molasses": IngredientRecord(
        score=6, category="neutral",
        reason="Contains iron and minerals but still a concentrated sugar",
        is_additive=False, aliases=("blackstrap molasses",)),
    "coconut sugar": IngredientRecord(
        score=6, category="neutral",
        reason="Lower glycemic than white sugar but still a sugar",
        is_additive=False, aliases=("coconut palm sugar",)),
    "stevia": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Plant-based sweetener with potential anti-inflammatory properties",
        is_additive=True, aliases=("stevia extract", "stevia leaf extract", "reb a", "rebaudioside a")),
    "monk fruit": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Natural zero-calorie sweetener with antioxidant properties",
        is_additive=True, aliases=("monk fruit extract", "luo han guo", "monkfruit")),
    "erythritol": IngredientRecord(
        score=5, category="neutral",
        reason="Sugar alcohol with minimal metabolic impact",
        is_additive=True, aliases=()),
    "xylitol": IngredientRecord(
        score=5, category="neutral",
        reason="Sugar alcohol with minimal inflammatory effect",
        is_additive=True, aliases=()),
    "sorbitol": IngredientRecord(
        score=6, category="neutral",
        reason="Sugar alcohol that may cause GI distress in large amounts",
        is_additive=True, aliases=("e420",)),
    "aspartame": IngredientRecord(
        score=8, category="inflammatory",
        reason="Artificial sweetener linked to gut microbiome disruption",
        is_additive=True, aliases=("e951", "nutrasweet", "equal")),
    "sucralose": IngredientRecord(
        score=7, category="inflammatory",
        reason="May alter gut microbiome and glucose metabolism",
        is_additive=True, aliases=("e955", "splenda")),
    "acesulfame potassium": IngredientRecord(
        score=7, category="inflammatory",
        reason="Artificial sweetener with potential metabolic disruption",
        is_additive=True, aliases=("acesulfame k", "ace-k", "e950")),
    "saccharin": IngredientRecord(
        score=7, category="inflammatory",
        reason="Artificial sweetener that may affect gut bacteria",
        is_additive=True, aliases=("e954", "sweet n low")),
    "neotame": IngredientRecord(
        score=7, category="inflammatory",
        reason="Artificial sweetener derived from aspartame",
        is_additive=True, aliases=("e961",)),
    "tagatose": IngredientRecord(
        score=5, category="neutral",
        reason="Naturally occurring sugar with lower glycemic index",
        is_additive=True, aliases=()),
    "allulose": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Rare sugar with minimal metabolic impact and potential anti-inflammatory effects",
        is_additive=True, aliases=("d-allulose", "d-psicose")),
    "rice syrup": IngredientRecord(
        score=8, category="inflammatory",
        reason="High glycemic index sweetener",
        is_additive=False, aliases=("brown rice syrup", "rice malt syrup")),
    "treacle": IngredientRecord(
        score=7, category="inflammatory",
        reason="Concentrated sugar syrup similar to molasses",
        is_additive=False, aliases=("golden syrup",)),
    "caramel": IngredientRecord(
        score=7, category="inflammatory",
        reason="Heated sugar that may contain advanced glycation end products",
        is_additive=False, aliases=()),

    # ── Fats & Oils (30) ──────────────────────────────────────────────────

    "olive oil": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in oleocanthal and polyphenols with strong anti-inflammatory effects",
        is_additive=False, aliases=("extra virgin olive oil", "evoo", "virgin olive oil")),
    "coconut oil": IngredientRecord(
        score=5, category="neutral",
        reason="Contains lauric acid; effects on inflammation are mixed",
        is_additive=False, aliases=("virgin coconut oil", "organic coconut oil")),
    "avocado oil": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="High in oleic acid and antioxidants",
        is_additive=False, aliases=()),
    "soybean oil": IngredientRecord(
        score=7, category="inflammatory",
        reason="High omega-6 to omega-3 ratio promotes inflammation",
        is_additive=False, aliases=("soy oil",)),
    "canola oil": IngredientRecord(
        score=5, category="neutral",
        reason="Moderate omega-6 content; relatively balanced fatty acid profile",
        is_additive=False, aliases=("rapeseed oil",)),
    "palm oil": IngredientRecord(
        score=7, category="inflammatory",
        reason="High in saturated fat and palmitic acid which promotes inflammation",
        is_additive=False, aliases=("palm fat", "palm kernel oil")),
    "sunflower oil": IngredientRecord(
        score=7, category="inflammatory",
        reason="Very high omega-6 content promotes inflammatory pathways",
        is_additive=False, aliases=("sunflower seed oil",)),
    "safflower oil": IngredientRecord(
        score=7, category="inflammatory",
        reason="High omega-6 linoleic acid content",
        is_additive=False, aliases=()),
    "corn oil": IngredientRecord(
        score=7, category="inflammatory",
        reason="High omega-6 content; commonly refined",
        is_additive=False, aliases=("maize oil",)),
    "cottonseed oil": IngredientRecord(
        score=8, category="inflammatory",
        reason="High omega-6, often heavily processed, may contain pesticide residues",
        is_additive=False, aliases=()),
    "vegetable oil": IngredientRecord(
        score=7, category="inflammatory",
        reason="Usually soybean or canola blend; high omega-6",
        is_additive=False, aliases=("vegetable fat",)),
    "partially hydrogenated oil": IngredientRecord(
        score=10, category="highly_inflammatory",
        reason="Contains trans fats which strongly promote systemic inflammation",
        is_additive=False, aliases=("partially hydrogenated soybean oil",
                                     "partially hydrogenated vegetable oil",
                                     "partially hydrogenated cottonseed oil")),
    "hydrogenated oil": IngredientRecord(
        score=9, category="highly_inflammatory",
        reason="Hydrogenation process creates inflammatory trans fats",
        is_additive=False, aliases=("hydrogenated vegetable oil", "hydrogenated soybean oil",
                                     "hydrogenated palm oil", "fully hydrogenated oil")),
    "shortening": IngredientRecord(
        score=8, category="inflammatory",
        reason="Often contains hydrogenated oils and trans fats",
        is_additive=False, aliases=("vegetable shortening",)),
    "margarine": IngredientRecord(
        score=7, category="inflammatory",
        reason="Processed fat that may contain trans fats and inflammatory omega-6",
        is_additive=False, aliases=()),
    "butter": IngredientRecord(
        score=6, category="neutral",
        reason="Contains some saturated fat but also butyrate which may be anti-inflammatory",
        is_additive=False, aliases=("cream butter", "sweet cream butter", "unsalted butter")),
    "ghee": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Clarified butter rich in butyrate and CLA with anti-inflammatory properties",
        is_additive=False, aliases=("clarified butter",)),
    "lard": IngredientRecord(
        score=6, category="neutral",
        reason="Animal fat with mixed fatty acid profile",
        is_additive=False, aliases=()),
    "tallow": IngredientRecord(
        score=6, category="neutral",
        reason="Rendered beef fat; moderate inflammatory potential",
        is_additive=False, aliases=("beef tallow", "beef fat")),
    "flaxseed oil": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Excellent source of anti-inflammatory omega-3 ALA",
        is_additive=False, aliases=("flax oil", "linseed oil")),
    "fish oil": IngredientRecord(
        score=1, category="highly_anti_inflammatory",
        reason="Rich in EPA and DHA omega-3 fatty acids with potent anti-inflammatory effects",
        is_additive=False, aliases=("omega-3 fish oil", "cod liver oil")),
    "walnut oil": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Good source of omega-3 ALA",
        is_additive=False, aliases=()),
    "sesame oil": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains sesamin and sesamol with anti-inflammatory properties",
        is_additive=False, aliases=("toasted sesame oil",)),
    "peanut oil": IngredientRecord(
        score=6, category="neutral",
        reason="Moderate omega-6 content; relatively stable for cooking",
        is_additive=False, aliases=("groundnut oil",)),
    "grapeseed oil": IngredientRecord(
        score=7, category="inflammatory",
        reason="Very high omega-6 content",
        is_additive=False, aliases=("grape seed oil",)),
    "rice bran oil": IngredientRecord(
        score=5, category="neutral",
        reason="Contains gamma-oryzanol which may have mild anti-inflammatory effects",
        is_additive=False, aliases=()),
    "mct oil": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Medium chain triglycerides are easily metabolized and may reduce inflammation",
        is_additive=False, aliases=("medium chain triglycerides",)),
    "hemp oil": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Good omega-3 to omega-6 ratio with GLA",
        is_additive=False, aliases=("hemp seed oil",)),
    "interesterified fat": IngredientRecord(
        score=8, category="inflammatory",
        reason="Chemically modified fat that may impair glucose metabolism",
        is_additive=False, aliases=("interesterified oil",)),
    "cocoa butter": IngredientRecord(
        score=5, category="neutral",
        reason="Saturated fat with some antioxidant properties from cocoa",
        is_additive=False, aliases=("cacao butter",)),

    # ── Grains & Starches (30) ────────────────────────────────────────────

    "whole wheat flour": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains fiber, vitamins, and phytonutrients",
        is_additive=False, aliases=("whole grain wheat flour", "stone ground whole wheat")),
    "wheat flour": IngredientRecord(
        score=7, category="inflammatory",
        reason="Refined flour stripped of fiber and nutrients; high glycemic",
        is_additive=False, aliases=("enriched wheat flour", "bleached wheat flour",
                                     "enriched flour", "bleached flour", "white flour",
                                     "all-purpose flour", "unbleached flour")),
    "oat flour": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains beta-glucan fiber with anti-inflammatory effects",
        is_additive=False, aliases=("whole oat flour",)),
    "oats": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in beta-glucan and avenanthramides which reduce inflammation",
        is_additive=False, aliases=("rolled oats", "whole grain oats", "steel cut oats", "oat")),
    "brown rice": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Whole grain with fiber and minerals",
        is_additive=False, aliases=("whole grain brown rice",)),
    "white rice": IngredientRecord(
        score=6, category="neutral",
        reason="Refined grain with moderate glycemic impact",
        is_additive=False, aliases=("rice", "enriched rice")),
    "cornstarch": IngredientRecord(
        score=6, category="neutral",
        reason="Refined starch used as thickener; moderate glycemic impact",
        is_additive=True, aliases=("corn starch", "maize starch")),
    "modified food starch": IngredientRecord(
        score=6, category="neutral",
        reason="Chemically or physically altered starch; generally recognized as safe",
        is_additive=True, aliases=("modified starch", "modified corn starch",
                                    "modified tapioca starch")),
    "tapioca starch": IngredientRecord(
        score=6, category="neutral",
        reason="Refined starch from cassava; high glycemic but generally neutral",
        is_additive=False, aliases=("tapioca", "tapioca flour", "cassava starch")),
    "potato starch": IngredientRecord(
        score=5, category="neutral",
        reason="Contains resistant starch which may benefit gut health",
        is_additive=False, aliases=()),
    "quinoa": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Complete protein with anti-inflammatory flavonoids",
        is_additive=False, aliases=("quinoa flour",)),
    "barley": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in beta-glucan fiber",
        is_additive=False, aliases=("pearl barley", "barley flour", "barley malt")),
    "buckwheat": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in rutin and quercetin antioxidants",
        is_additive=False, aliases=("buckwheat flour",)),
    "millet": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Whole grain with good mineral content",
        is_additive=False, aliases=("millet flour",)),
    "amaranth": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Ancient grain rich in anti-inflammatory compounds",
        is_additive=False, aliases=("amaranth flour",)),
    "spelt": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Ancient wheat variety with more nutrients than modern wheat",
        is_additive=False, aliases=("spelt flour",)),
    "rye": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Whole grain with high fiber content",
        is_additive=False, aliases=("rye flour", "whole rye")),
    "semolina": IngredientRecord(
        score=6, category="neutral",
        reason="Refined durum wheat product",
        is_additive=False, aliases=("durum wheat semolina",)),
    "rice flour": IngredientRecord(
        score=6, category="neutral",
        reason="Refined grain flour with moderate glycemic impact",
        is_additive=False, aliases=("white rice flour",)),
    "wheat gluten": IngredientRecord(
        score=7, category="inflammatory",
        reason="Concentrated gluten protein that may promote gut inflammation",
        is_additive=True, aliases=("vital wheat gluten", "seitan")),
    "corn flour": IngredientRecord(
        score=6, category="neutral",
        reason="Ground corn; moderate glycemic impact",
        is_additive=False, aliases=("cornmeal", "corn meal", "masa")),
    "wheat bran": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="High fiber outer layer of wheat kernel",
        is_additive=False, aliases=()),
    "oat bran": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in beta-glucan soluble fiber",
        is_additive=False, aliases=()),
    "arrowroot": IngredientRecord(
        score=5, category="neutral",
        reason="Easily digestible starch with minimal inflammatory impact",
        is_additive=False, aliases=("arrowroot starch", "arrowroot flour")),
    "teff": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Ancient grain rich in iron and resistant starch",
        is_additive=False, aliases=("teff flour",)),
    "sorghum": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Whole grain with good antioxidant content",
        is_additive=False, aliases=("sorghum flour",)),
    "farro": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Ancient wheat variety with fiber and nutrients",
        is_additive=False, aliases=()),
    "kamut": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Ancient wheat with higher protein and mineral content",
        is_additive=False, aliases=("khorasan wheat",)),
    "freekeh": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Young green wheat with high fiber and prebiotic content",
        is_additive=False, aliases=()),
    "breadcrumbs": IngredientRecord(
        score=7, category="inflammatory",
        reason="Made from refined white bread; high glycemic",
        is_additive=False, aliases=("bread crumbs", "panko")),

    # ── Proteins (20) ─────────────────────────────────────────────────────

    "whey protein": IngredientRecord(
        score=5, category="neutral",
        reason="High-quality protein; may cause inflammation in lactose-sensitive individuals",
        is_additive=False, aliases=("whey protein concentrate", "whey protein isolate", "whey")),
    "casein": IngredientRecord(
        score=6, category="neutral",
        reason="Milk protein that some people find inflammatory",
        is_additive=False, aliases=("sodium caseinate", "calcium caseinate", "caseinates")),
    "pea protein": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Plant-based protein with good amino acid profile",
        is_additive=False, aliases=("pea protein isolate",)),
    "soy protein": IngredientRecord(
        score=5, category="neutral",
        reason="Plant protein; isoflavones may have mild anti-inflammatory effects",
        is_additive=False, aliases=("soy protein isolate", "soy protein concentrate",
                                     "textured soy protein", "isolated soy protein")),
    "hemp protein": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains anti-inflammatory omega-3 and GLA",
        is_additive=False, aliases=("hemp seed protein",)),
    "collagen": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="May support joint health and reduce inflammation",
        is_additive=False, aliases=("collagen peptides", "hydrolyzed collagen")),
    "gelatin": IngredientRecord(
        score=5, category="neutral",
        reason="Derived from collagen; neutral inflammatory impact",
        is_additive=True, aliases=()),
    "egg white": IngredientRecord(
        score=5, category="neutral",
        reason="High-quality protein with neutral inflammatory effects",
        is_additive=False, aliases=("egg white powder", "dried egg whites", "albumen")),
    "egg": IngredientRecord(
        score=5, category="neutral",
        reason="Complete protein with choline; generally neutral for inflammation",
        is_additive=False, aliases=("whole egg", "eggs", "egg yolk", "dried egg")),
    "chicken": IngredientRecord(
        score=5, category="neutral",
        reason="Lean protein source with neutral inflammatory impact",
        is_additive=False, aliases=("chicken breast", "chicken meat")),
    "beef": IngredientRecord(
        score=6, category="neutral",
        reason="Moderate inflammatory potential from saturated fat and arachidonic acid",
        is_additive=False, aliases=("beef extract",)),
    "pork": IngredientRecord(
        score=6, category="neutral",
        reason="Moderate saturated fat content",
        is_additive=False, aliases=()),
    "salmon": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Excellent source of anti-inflammatory omega-3 EPA and DHA",
        is_additive=False, aliases=("wild salmon", "atlantic salmon")),
    "sardines": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in omega-3 fatty acids",
        is_additive=False, aliases=("sardine",)),
    "tuna": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Good source of omega-3 fatty acids",
        is_additive=False, aliases=("skipjack tuna", "albacore tuna")),
    "anchovies": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="High in omega-3 fatty acids",
        is_additive=False, aliases=("anchovy", "anchovy extract")),
    "rice protein": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Hypoallergenic plant protein",
        is_additive=False, aliases=("brown rice protein",)),
    "cricket protein": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Sustainable protein with chitin that may have anti-inflammatory effects",
        is_additive=False, aliases=("cricket flour",)),
    "spirulina": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Blue-green algae with powerful anti-inflammatory phycocyanin",
        is_additive=False, aliases=()),
    "chlorella": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Algae with anti-inflammatory and detoxification properties",
        is_additive=False, aliases=()),

    # ── Vegetables (30) ───────────────────────────────────────────────────

    "spinach": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in anti-inflammatory flavonoids and carotenoids",
        is_additive=False, aliases=("spinach powder",)),
    "broccoli": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Contains sulforaphane, a potent anti-inflammatory compound",
        is_additive=False, aliases=("broccoli powder", "broccoli extract")),
    "kale": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="High in anti-inflammatory vitamin K and flavonoids",
        is_additive=False, aliases=("kale powder",)),
    "garlic": IngredientRecord(
        score=1, category="highly_anti_inflammatory",
        reason="Allicin and sulfur compounds strongly inhibit inflammatory pathways",
        is_additive=False, aliases=("garlic powder", "garlic extract", "roasted garlic",
                                     "minced garlic", "dehydrated garlic")),
    "ginger": IngredientRecord(
        score=1, category="highly_anti_inflammatory",
        reason="Gingerols are potent inhibitors of COX-2 and inflammatory cytokines",
        is_additive=False, aliases=("ginger root", "ginger extract", "ginger powder",
                                     "dried ginger", "ground ginger")),
    "onion": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in quercetin and sulfur compounds",
        is_additive=False, aliases=("onion powder", "dehydrated onion", "onions",
                                     "dried onion", "red onion")),
    "tomato": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in lycopene, a powerful anti-inflammatory antioxidant",
        is_additive=False, aliases=("tomatoes", "tomato paste", "tomato puree",
                                     "tomato powder", "tomato concentrate", "diced tomatoes",
                                     "crushed tomatoes")),
    "sweet potato": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in beta-carotene and anti-inflammatory anthocyanins",
        is_additive=False, aliases=("sweet potatoes",)),
    "beet": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains betalains with anti-inflammatory properties",
        is_additive=False, aliases=("beets", "beetroot", "beet juice", "beet powder")),
    "carrot": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Rich in beta-carotene and fiber",
        is_additive=False, aliases=("carrots", "carrot juice")),
    "celery": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains luteolin and apigenin anti-inflammatory flavonoids",
        is_additive=False, aliases=("celery powder", "celery seed")),
    "cucumber": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains cucurbitacins with anti-inflammatory properties",
        is_additive=False, aliases=("cucumbers",)),
    "bell pepper": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Excellent source of vitamin C and anti-inflammatory carotenoids",
        is_additive=False, aliases=("bell peppers", "red pepper", "green pepper")),
    "mushroom": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains beta-glucans and ergothioneine with anti-inflammatory effects",
        is_additive=False, aliases=("mushrooms", "shiitake", "portobello", "mushroom powder")),
    "asparagus": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in anti-inflammatory saponins and flavonoids",
        is_additive=False, aliases=()),
    "cauliflower": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Cruciferous vegetable with anti-inflammatory glucosinolates",
        is_additive=False, aliases=()),
    "cabbage": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains anthocyanins and glucosinolates",
        is_additive=False, aliases=("red cabbage", "green cabbage")),
    "brussels sprouts": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Cruciferous vegetable rich in anti-inflammatory compounds",
        is_additive=False, aliases=("brussel sprouts",)),
    "zucchini": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Low-calorie vegetable with antioxidants",
        is_additive=False, aliases=("courgette",)),
    "eggplant": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains nasunin, a potent antioxidant",
        is_additive=False, aliases=("aubergine",)),
    "artichoke": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in cynarin and chlorogenic acid",
        is_additive=False, aliases=("artichoke hearts", "artichoke extract")),
    "seaweed": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in fucoidans with potent anti-inflammatory activity",
        is_additive=False, aliases=("kelp", "nori", "wakame", "dulse", "kombu")),
    "watercress": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Potent source of anti-inflammatory phenethyl isothiocyanate",
        is_additive=False, aliases=()),
    "arugula": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Cruciferous green with anti-inflammatory glucosinolates",
        is_additive=False, aliases=("rocket",)),
    "lettuce": IngredientRecord(
        score=5, category="neutral",
        reason="Mild vegetable with minimal inflammatory impact",
        is_additive=False, aliases=("romaine lettuce", "iceberg lettuce")),
    "potato": IngredientRecord(
        score=5, category="neutral",
        reason="Starchy vegetable; moderate glycemic impact",
        is_additive=False, aliases=("potatoes", "potato flakes", "potato starch",
                                     "dehydrated potatoes")),
    "corn": IngredientRecord(
        score=5, category="neutral",
        reason="Whole grain; moderate inflammatory potential",
        is_additive=False, aliases=("sweet corn", "whole corn")),
    "peas": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Good source of fiber and anti-inflammatory flavonoids",
        is_additive=False, aliases=("green peas", "pea fiber")),
    "green beans": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Low-calorie vegetable with antioxidants",
        is_additive=False, aliases=("string beans",)),
    "radish": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains isothiocyanates with anti-inflammatory effects",
        is_additive=False, aliases=("radishes", "daikon")),

    # ── Fruits (20) ───────────────────────────────────────────────────────

    "blueberry": IngredientRecord(
        score=1, category="highly_anti_inflammatory",
        reason="Exceptionally rich in anti-inflammatory anthocyanins and pterostilbene",
        is_additive=False, aliases=("blueberries", "blueberry powder", "blueberry extract")),
    "cherry": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Tart cherries contain potent anti-inflammatory anthocyanins",
        is_additive=False, aliases=("cherries", "tart cherry", "tart cherries", "cherry extract")),
    "pomegranate": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in punicalagins and ellagic acid with strong anti-inflammatory effects",
        is_additive=False, aliases=("pomegranate juice", "pomegranate extract")),
    "cranberry": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in proanthocyanidins with anti-inflammatory effects",
        is_additive=False, aliases=("cranberries", "cranberry extract")),
    "apple": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains quercetin and pectin fiber",
        is_additive=False, aliases=("apples", "apple juice concentrate", "apple puree")),
    "grape": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains resveratrol and anti-inflammatory polyphenols",
        is_additive=False, aliases=("grapes", "grape juice", "grape extract")),
    "orange": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="High in vitamin C and hesperidin",
        is_additive=False, aliases=("oranges", "orange juice", "orange peel")),
    "lemon": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in vitamin C and limonene",
        is_additive=False, aliases=("lemon juice", "lemon zest", "lemon peel")),
    "lime": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in vitamin C and flavonoids",
        is_additive=False, aliases=("lime juice",)),
    "strawberry": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains ellagic acid and anthocyanins",
        is_additive=False, aliases=("strawberries",)),
    "raspberry": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in ellagic acid and anti-inflammatory ellagitannins",
        is_additive=False, aliases=("raspberries",)),
    "blackberry": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="High in anthocyanins and ellagic acid",
        is_additive=False, aliases=("blackberries",)),
    "banana": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains dopamine and catechins with anti-inflammatory effects",
        is_additive=False, aliases=("bananas", "banana puree")),
    "pineapple": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains bromelain enzyme with anti-inflammatory properties",
        is_additive=False, aliases=("pineapple juice",)),
    "mango": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Rich in mangiferin with anti-inflammatory and antioxidant effects",
        is_additive=False, aliases=("mangoes",)),
    "papaya": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains papain enzyme and vitamin C",
        is_additive=False, aliases=()),
    "avocado": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in oleic acid, glutathione, and anti-inflammatory phytosterols",
        is_additive=False, aliases=("avocados",)),
    "acai": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Extremely high in anti-inflammatory anthocyanins",
        is_additive=False, aliases=("acai berry", "acai powder", "acai extract")),
    "goji berry": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in zeaxanthin and anti-inflammatory polysaccharides",
        is_additive=False, aliases=("goji berries", "wolfberry")),
    "date": IngredientRecord(
        score=5, category="neutral",
        reason="High in sugar but contains fiber and antioxidants",
        is_additive=False, aliases=("dates", "date paste", "date syrup")),

    # ── Spices & Herbs (30) ───────────────────────────────────────────────

    "turmeric": IngredientRecord(
        score=1, category="highly_anti_inflammatory",
        reason="Curcumin is one of the most potent natural anti-inflammatory compounds known",
        is_additive=False, aliases=("turmeric powder", "turmeric extract", "curcumin",
                                     "ground turmeric")),
    "cinnamon": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Contains cinnamaldehyde which inhibits NF-kB inflammatory pathway",
        is_additive=False, aliases=("ground cinnamon", "ceylon cinnamon", "cassia cinnamon",
                                     "cinnamon extract")),
    "black pepper": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Piperine has anti-inflammatory properties and enhances curcumin absorption",
        is_additive=False, aliases=("pepper", "ground black pepper", "piperine")),
    "cayenne pepper": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Capsaicin has significant anti-inflammatory and pain-relieving properties",
        is_additive=False, aliases=("cayenne", "capsaicin", "red pepper flakes",
                                     "crushed red pepper")),
    "oregano": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Contains carvacrol and rosmarinic acid with potent anti-inflammatory effects",
        is_additive=False, aliases=("oregano extract",)),
    "rosemary": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in carnosic acid and rosmarinic acid",
        is_additive=False, aliases=("rosemary extract", "rosemary powder")),
    "thyme": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Contains thymol with anti-inflammatory properties",
        is_additive=False, aliases=()),
    "basil": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Contains eugenol which inhibits COX enzymes",
        is_additive=False, aliases=("sweet basil", "holy basil", "tulsi")),
    "sage": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Contains carnosol and carnosic acid",
        is_additive=False, aliases=()),
    "clove": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Highest ORAC value among spices; eugenol is strongly anti-inflammatory",
        is_additive=False, aliases=("cloves", "ground cloves")),
    "cumin": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains thymoquinone with anti-inflammatory properties",
        is_additive=False, aliases=("ground cumin",)),
    "coriander": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains linalool with anti-inflammatory and antioxidant effects",
        is_additive=False, aliases=("cilantro", "coriander seed")),
    "cardamom": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains 1,8-cineole with anti-inflammatory properties",
        is_additive=False, aliases=()),
    "fennel": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains anethole which may inhibit NF-kB",
        is_additive=False, aliases=("fennel seed",)),
    "nutmeg": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains myristicin with mild anti-inflammatory effects",
        is_additive=False, aliases=("ground nutmeg",)),
    "paprika": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains capsanthin antioxidant",
        is_additive=False, aliases=("smoked paprika",)),
    "allspice": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains eugenol with anti-inflammatory properties",
        is_additive=False, aliases=()),
    "star anise": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains shikimic acid with anti-inflammatory properties",
        is_additive=False, aliases=()),
    "bay leaf": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains parthenolide with anti-inflammatory effects",
        is_additive=False, aliases=("bay leaves",)),
    "mustard": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains isothiocyanates with anti-inflammatory potential",
        is_additive=False, aliases=("mustard seed", "mustard powder", "ground mustard",
                                     "yellow mustard")),
    "parsley": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in apigenin and vitamin K",
        is_additive=False, aliases=("dried parsley",)),
    "dill": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains monoterpenes with anti-inflammatory effects",
        is_additive=False, aliases=("dill weed",)),
    "mint": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains rosmarinic acid with anti-inflammatory properties",
        is_additive=False, aliases=("peppermint", "spearmint")),
    "saffron": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Contains crocin and safranal with potent anti-inflammatory effects",
        is_additive=False, aliases=()),
    "chili pepper": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Capsaicin has anti-inflammatory and analgesic properties",
        is_additive=False, aliases=("chili", "chili powder", "hot pepper")),
    "fenugreek": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains diosgenin with anti-inflammatory effects",
        is_additive=False, aliases=("fenugreek seed",)),
    "vanilla": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains vanillin with mild antioxidant properties",
        is_additive=False, aliases=("vanilla extract", "vanilla bean", "natural vanilla")),
    "cocoa": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in flavanols with anti-inflammatory effects",
        is_additive=False, aliases=("cocoa powder", "cacao", "cacao powder", "dark chocolate")),
    "matcha": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Concentrated green tea catechins with strong anti-inflammatory effects",
        is_additive=False, aliases=("matcha powder",)),
    "green tea": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in EGCG catechin which powerfully inhibits inflammatory pathways",
        is_additive=False, aliases=("green tea extract",)),

    # ── Dairy (20) ────────────────────────────────────────────────────────

    "milk": IngredientRecord(
        score=6, category="neutral",
        reason="Contains both pro- and anti-inflammatory components",
        is_additive=False, aliases=("whole milk", "skim milk", "nonfat milk",
                                     "reduced fat milk", "milk powder", "dry milk",
                                     "nonfat dry milk", "milk solids")),
    "cream": IngredientRecord(
        score=6, category="neutral",
        reason="High in saturated fat but contains some beneficial short-chain fatty acids",
        is_additive=False, aliases=("heavy cream", "whipping cream", "light cream",
                                     "half and half")),
    "yogurt": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Probiotics support gut health and may reduce inflammation",
        is_additive=False, aliases=("greek yogurt", "plain yogurt")),
    "kefir": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in diverse probiotics with anti-inflammatory effects",
        is_additive=False, aliases=()),
    "cheese": IngredientRecord(
        score=6, category="neutral",
        reason="Contains saturated fat but also CLA and vitamin K2",
        is_additive=False, aliases=("cheddar cheese", "mozzarella", "parmesan",
                                     "swiss cheese", "provolone")),
    "cream cheese": IngredientRecord(
        score=6, category="neutral",
        reason="Processed dairy product with moderate saturated fat",
        is_additive=False, aliases=()),
    "sour cream": IngredientRecord(
        score=6, category="neutral",
        reason="Fermented dairy with moderate inflammatory potential",
        is_additive=False, aliases=()),
    "cottage cheese": IngredientRecord(
        score=5, category="neutral",
        reason="Higher protein dairy with moderate inflammatory potential",
        is_additive=False, aliases=()),
    "ricotta": IngredientRecord(
        score=5, category="neutral",
        reason="Whey-based cheese with moderate inflammatory potential",
        is_additive=False, aliases=("ricotta cheese",)),
    "ice cream": IngredientRecord(
        score=7, category="inflammatory",
        reason="High in sugar and saturated fat",
        is_additive=False, aliases=()),
    "processed cheese": IngredientRecord(
        score=7, category="inflammatory",
        reason="Contains emulsifiers and artificial ingredients",
        is_additive=False, aliases=("american cheese", "cheese product",
                                     "pasteurized process cheese")),
    "almond milk": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Low-inflammatory dairy alternative",
        is_additive=False, aliases=("almondmilk",)),
    "oat milk": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains beta-glucan with anti-inflammatory effects",
        is_additive=False, aliases=("oatmilk",)),
    "soy milk": IngredientRecord(
        score=5, category="neutral",
        reason="Contains isoflavones; neutral to mildly anti-inflammatory",
        is_additive=False, aliases=("soymilk",)),
    "coconut milk": IngredientRecord(
        score=5, category="neutral",
        reason="Contains lauric acid with mixed effects on inflammation",
        is_additive=False, aliases=("coconut cream",)),
    "buttermilk": IngredientRecord(
        score=5, category="neutral",
        reason="Fermented dairy with some probiotic benefits",
        is_additive=False, aliases=()),
    "evaporated milk": IngredientRecord(
        score=6, category="neutral",
        reason="Concentrated milk with higher sugar content",
        is_additive=False, aliases=()),
    "condensed milk": IngredientRecord(
        score=8, category="inflammatory",
        reason="Very high in sugar; concentrated inflammatory sweetened dairy",
        is_additive=False, aliases=("sweetened condensed milk",)),
    "goat milk": IngredientRecord(
        score=5, category="neutral",
        reason="May be less inflammatory than cow milk for some individuals",
        is_additive=False, aliases=("goat cheese",)),
    "whipped cream": IngredientRecord(
        score=6, category="neutral",
        reason="High in saturated fat and often contains added sugar",
        is_additive=False, aliases=("whipped topping",)),

    # ── Preservatives (30) ────────────────────────────────────────────────

    "sodium benzoate": IngredientRecord(
        score=7, category="inflammatory",
        reason="May trigger inflammatory responses and histamine release",
        is_additive=True, aliases=("e211",)),
    "potassium sorbate": IngredientRecord(
        score=6, category="neutral",
        reason="Generally well-tolerated preservative with minimal inflammatory effects",
        is_additive=True, aliases=("e202",)),
    "sodium nitrite": IngredientRecord(
        score=8, category="inflammatory",
        reason="Forms nitrosamines which promote inflammation and are potentially carcinogenic",
        is_additive=True, aliases=("e250", "sodium nitrate", "e251")),
    "bha": IngredientRecord(
        score=8, category="inflammatory",
        reason="Butylated hydroxyanisole may disrupt endocrine function and promote inflammation",
        is_additive=True, aliases=("butylated hydroxyanisole", "e320")),
    "bht": IngredientRecord(
        score=7, category="inflammatory",
        reason="Butylated hydroxytoluene; synthetic antioxidant with potential inflammatory effects",
        is_additive=True, aliases=("butylated hydroxytoluene", "e321")),
    "tbhq": IngredientRecord(
        score=8, category="inflammatory",
        reason="Tertiary butylhydroquinone may impair immune function",
        is_additive=True, aliases=("tert-butylhydroquinone", "e319")),
    "sodium metabisulfite": IngredientRecord(
        score=7, category="inflammatory",
        reason="Sulfite preservative that can trigger inflammatory and allergic reactions",
        is_additive=True, aliases=("e223", "sodium bisulfite", "sulfites",
                                    "sulfur dioxide", "e220", "e222", "e224")),
    "calcium propionate": IngredientRecord(
        score=6, category="neutral",
        reason="Bread preservative with some evidence of behavioral effects in children",
        is_additive=True, aliases=("e282", "sodium propionate")),
    "sorbic acid": IngredientRecord(
        score=5, category="neutral",
        reason="Natural preservative with minimal inflammatory effects",
        is_additive=True, aliases=("e200",)),
    "ascorbic acid": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Vitamin C; antioxidant with anti-inflammatory properties",
        is_additive=True, aliases=("vitamin c", "e300", "sodium ascorbate")),
    "tocopherol": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Vitamin E; natural antioxidant with anti-inflammatory effects",
        is_additive=True, aliases=("vitamin e", "mixed tocopherols", "alpha-tocopherol",
                                    "e307", "e308", "e309")),
    "citric acid": IngredientRecord(
        score=5, category="neutral",
        reason="Natural acid found in citrus; generally non-inflammatory as preservative",
        is_additive=True, aliases=("e330",)),
    "lactic acid": IngredientRecord(
        score=5, category="neutral",
        reason="Naturally occurring acid in fermented foods",
        is_additive=True, aliases=("e270",)),
    "malic acid": IngredientRecord(
        score=5, category="neutral",
        reason="Natural acid found in fruits",
        is_additive=True, aliases=("e296",)),
    "tartaric acid": IngredientRecord(
        score=5, category="neutral",
        reason="Natural acid found in grapes and wine",
        is_additive=True, aliases=("e334", "cream of tartar")),
    "phosphoric acid": IngredientRecord(
        score=7, category="inflammatory",
        reason="May leach calcium and promote bone inflammation at high doses",
        is_additive=True, aliases=("e338",)),
    "acetic acid": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Active component of vinegar with potential anti-inflammatory effects",
        is_additive=True, aliases=("e260",)),
    "benzoic acid": IngredientRecord(
        score=7, category="inflammatory",
        reason="May cause pseudo-allergic reactions and inflammatory responses",
        is_additive=True, aliases=("e210",)),
    "propionic acid": IngredientRecord(
        score=5, category="neutral",
        reason="Short-chain fatty acid also produced by gut bacteria",
        is_additive=True, aliases=("e280",)),
    "natamycin": IngredientRecord(
        score=5, category="neutral",
        reason="Antifungal preservative with minimal systemic effects",
        is_additive=True, aliases=("e235",)),
    "nisin": IngredientRecord(
        score=5, category="neutral",
        reason="Natural antimicrobial peptide used as preservative",
        is_additive=True, aliases=("e234",)),
    "potassium benzoate": IngredientRecord(
        score=7, category="inflammatory",
        reason="Similar inflammatory profile to sodium benzoate",
        is_additive=True, aliases=("e212",)),
    "calcium disodium edta": IngredientRecord(
        score=6, category="neutral",
        reason="Chelating agent; generally well-tolerated at food-level doses",
        is_additive=True, aliases=("edta", "disodium edta", "e385")),
    "sodium erythorbate": IngredientRecord(
        score=5, category="neutral",
        reason="Isomer of vitamin C; used as antioxidant preservative",
        is_additive=True, aliases=("e316",)),
    "dimethyl dicarbonate": IngredientRecord(
        score=5, category="neutral",
        reason="Beverage sterilizer that breaks down quickly; minimal health impact",
        is_additive=True, aliases=("e242",)),
    "sodium sulfite": IngredientRecord(
        score=7, category="inflammatory",
        reason="Sulfite that may trigger asthma and inflammatory responses",
        is_additive=True, aliases=("e221",)),
    "potassium nitrate": IngredientRecord(
        score=7, category="inflammatory",
        reason="Converts to nitrites which form inflammatory nitrosamines",
        is_additive=True, aliases=("e252",)),
    "methylparaben": IngredientRecord(
        score=7, category="inflammatory",
        reason="Endocrine disruptor that may promote inflammatory responses",
        is_additive=True, aliases=("e218",)),
    "propylparaben": IngredientRecord(
        score=7, category="inflammatory",
        reason="Endocrine disruptor linked to inflammatory responses",
        is_additive=True, aliases=("e216",)),
    "hexamethylenetetramine": IngredientRecord(
        score=7, category="inflammatory",
        reason="Formaldehyde-releasing preservative with irritant properties",
        is_additive=True, aliases=("e239",)),

    # ── Colorings (20) ────────────────────────────────────────────────────

    "red 40": IngredientRecord(
        score=9, category="highly_inflammatory",
        reason="Petroleum-derived azo dye linked to hyperactivity and inflammatory responses",
        is_additive=True, aliases=("allura red", "e129", "fd&c red 40", "red 40 lake")),
    "yellow 5": IngredientRecord(
        score=9, category="highly_inflammatory",
        reason="Azo dye associated with hyperactivity and allergic inflammatory reactions",
        is_additive=True, aliases=("tartrazine", "e102", "fd&c yellow 5")),
    "yellow 6": IngredientRecord(
        score=9, category="highly_inflammatory",
        reason="Azo dye linked to allergic reactions and inflammation",
        is_additive=True, aliases=("sunset yellow", "e110", "fd&c yellow 6")),
    "blue 1": IngredientRecord(
        score=8, category="inflammatory",
        reason="Synthetic dye with potential for allergic inflammatory responses",
        is_additive=True, aliases=("brilliant blue", "e133", "fd&c blue 1")),
    "blue 2": IngredientRecord(
        score=8, category="inflammatory",
        reason="Synthetic indigo dye with limited safety data",
        is_additive=True, aliases=("indigo carmine", "e132", "fd&c blue 2")),
    "red 3": IngredientRecord(
        score=9, category="highly_inflammatory",
        reason="Banned in cosmetics; linked to thyroid tumors and inflammation",
        is_additive=True, aliases=("erythrosine", "e127", "fd&c red 3")),
    "green 3": IngredientRecord(
        score=8, category="inflammatory",
        reason="Synthetic dye with limited safety studies",
        is_additive=True, aliases=("fast green", "e143", "fd&c green 3")),
    "caramel color": IngredientRecord(
        score=7, category="inflammatory",
        reason="Class III and IV caramel colors contain 4-MEI, a potential carcinogen",
        is_additive=True, aliases=("caramel colour", "e150", "e150a", "e150b",
                                    "e150c", "e150d")),
    "annatto": IngredientRecord(
        score=5, category="neutral",
        reason="Natural plant-derived coloring with bixin antioxidant",
        is_additive=True, aliases=("annatto extract", "e160b", "annatto color")),
    "beta carotene": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Natural pigment with antioxidant and anti-inflammatory properties",
        is_additive=True, aliases=("beta-carotene", "e160a")),
    "paprika extract": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Natural coloring from paprika with capsanthin antioxidant",
        is_additive=True, aliases=("paprika oleoresin", "e160c")),
    "turmeric extract": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Natural coloring with curcumin anti-inflammatory compound",
        is_additive=True, aliases=("turmeric oleoresin", "e100", "curcumin color")),
    "beet juice color": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Natural coloring from beets with betaine antioxidants",
        is_additive=True, aliases=("beet juice concentrate", "betanin", "e162")),
    "titanium dioxide": IngredientRecord(
        score=8, category="inflammatory",
        reason="Nanoparticles may cause gut inflammation; banned in EU as food additive",
        is_additive=True, aliases=("e171",)),
    "carmine": IngredientRecord(
        score=5, category="neutral",
        reason="Natural insect-derived coloring; generally non-inflammatory",
        is_additive=True, aliases=("cochineal", "e120", "carmine color")),
    "chlorophyll": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Natural plant pigment with anti-inflammatory and antioxidant effects",
        is_additive=True, aliases=("chlorophyllin", "e140", "e141")),
    "riboflavin": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Vitamin B2; essential nutrient used as yellow coloring",
        is_additive=True, aliases=("vitamin b2", "e101")),
    "lycopene": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Powerful carotenoid antioxidant from tomatoes",
        is_additive=True, aliases=("e160d",)),
    "anthocyanins": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Plant pigments with potent anti-inflammatory effects",
        is_additive=True, aliases=("e163",)),
    "carbon black": IngredientRecord(
        score=7, category="inflammatory",
        reason="Synthetic black coloring with potential inflammatory properties",
        is_additive=True, aliases=("e153", "vegetable carbon")),

    # ── Emulsifiers & Stabilizers (30) ────────────────────────────────────

    "soy lecithin": IngredientRecord(
        score=5, category="neutral",
        reason="Common emulsifier with choline; generally well-tolerated",
        is_additive=True, aliases=("lecithin", "soya lecithin", "e322")),
    "sunflower lecithin": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Non-GMO emulsifier with good phospholipid profile",
        is_additive=True, aliases=()),
    "xanthan gum": IngredientRecord(
        score=5, category="neutral",
        reason="Fermentation-derived thickener; generally non-inflammatory",
        is_additive=True, aliases=("e415",)),
    "guar gum": IngredientRecord(
        score=5, category="neutral",
        reason="Soluble fiber from guar beans; may have prebiotic effects",
        is_additive=True, aliases=("e412",)),
    "carrageenan": IngredientRecord(
        score=8, category="inflammatory",
        reason="Linked to gut inflammation and intestinal permeability in research studies",
        is_additive=True, aliases=("e407", "irish moss")),
    "cellulose gum": IngredientRecord(
        score=5, category="neutral",
        reason="Indigestible plant fiber; generally non-inflammatory",
        is_additive=True, aliases=("carboxymethyl cellulose", "cmc", "e466")),
    "cellulose": IngredientRecord(
        score=5, category="neutral",
        reason="Plant fiber used as anti-caking agent; inert",
        is_additive=True, aliases=("powdered cellulose", "microcrystalline cellulose",
                                    "e460")),
    "pectin": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Soluble fiber from fruits with prebiotic properties",
        is_additive=True, aliases=("e440",)),
    "agar": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Seaweed-derived gelling agent with prebiotic fiber",
        is_additive=True, aliases=("agar agar", "e406")),
    "gellan gum": IngredientRecord(
        score=5, category="neutral",
        reason="Fermentation-derived gelling agent; generally non-inflammatory",
        is_additive=True, aliases=("e418",)),
    "locust bean gum": IngredientRecord(
        score=5, category="neutral",
        reason="Natural seed gum with soluble fiber properties",
        is_additive=True, aliases=("carob bean gum", "e410")),
    "acacia gum": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Prebiotic soluble fiber with some anti-inflammatory effects",
        is_additive=True, aliases=("gum arabic", "e414")),
    "tara gum": IngredientRecord(
        score=5, category="neutral",
        reason="Natural seed gum; limited inflammatory effects",
        is_additive=True, aliases=("e417",)),
    "mono and diglycerides": IngredientRecord(
        score=6, category="neutral",
        reason="Emulsifiers that may contain trans fats depending on source",
        is_additive=True, aliases=("mono- and diglycerides", "e471",
                                    "monoglycerides", "diglycerides")),
    "polysorbate 80": IngredientRecord(
        score=8, category="inflammatory",
        reason="Synthetic emulsifier linked to gut inflammation and microbiome disruption",
        is_additive=True, aliases=("e433", "tween 80")),
    "polysorbate 60": IngredientRecord(
        score=7, category="inflammatory",
        reason="Synthetic emulsifier with potential gut inflammatory effects",
        is_additive=True, aliases=("e435",)),
    "sodium stearoyl lactylate": IngredientRecord(
        score=6, category="neutral",
        reason="Dough conditioner; generally well-tolerated",
        is_additive=True, aliases=("ssl", "e481")),
    "calcium stearoyl lactylate": IngredientRecord(
        score=6, category="neutral",
        reason="Emulsifier similar to SSL; generally well-tolerated",
        is_additive=True, aliases=("csl", "e482")),
    "datem": IngredientRecord(
        score=6, category="neutral",
        reason="Dough strengthener; generally non-inflammatory at food levels",
        is_additive=True, aliases=("e472e", "diacetyl tartaric acid esters")),
    "sorbitan monostearate": IngredientRecord(
        score=6, category="neutral",
        reason="Emulsifier used in baking; limited inflammatory evidence",
        is_additive=True, aliases=("e491", "span 60")),
    "polyglycerol esters": IngredientRecord(
        score=6, category="neutral",
        reason="Emulsifier class with limited inflammatory evidence",
        is_additive=True, aliases=("e475", "polyglycerol polyricinoleate", "e476")),
    "sodium alginate": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Seaweed-derived with potential prebiotic and anti-inflammatory properties",
        is_additive=True, aliases=("alginic acid", "e401", "e400")),
    "konjac gum": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Glucomannan fiber with prebiotic and satiety-promoting effects",
        is_additive=True, aliases=("glucomannan", "e425")),
    "tragacanth gum": IngredientRecord(
        score=5, category="neutral",
        reason="Natural plant gum; generally inert",
        is_additive=True, aliases=("e413",)),
    "karaya gum": IngredientRecord(
        score=5, category="neutral",
        reason="Natural gum with limited inflammatory effects",
        is_additive=True, aliases=("e416",)),
    "methylcellulose": IngredientRecord(
        score=5, category="neutral",
        reason="Semi-synthetic cellulose derivative; generally inert",
        is_additive=True, aliases=("e461",)),
    "hydroxypropyl methylcellulose": IngredientRecord(
        score=5, category="neutral",
        reason="Cellulose derivative used as thickener; generally non-inflammatory",
        is_additive=True, aliases=("hpmc", "e464")),
    "silicon dioxide": IngredientRecord(
        score=5, category="neutral",
        reason="Anti-caking agent; passes through digestive system",
        is_additive=True, aliases=("silica", "e551")),
    "calcium silicate": IngredientRecord(
        score=5, category="neutral",
        reason="Anti-caking agent with minimal biological activity",
        is_additive=True, aliases=("e552",)),
    "magnesium stearate": IngredientRecord(
        score=5, category="neutral",
        reason="Flow agent used in supplements; minimal inflammatory effects",
        is_additive=True, aliases=("e572",)),

    # ── Flavor Enhancers (15) ─────────────────────────────────────────────

    "monosodium glutamate": IngredientRecord(
        score=8, category="inflammatory",
        reason="Excitotoxin that may promote neuroinflammation and oxidative stress",
        is_additive=True, aliases=("msg", "e621", "glutamate", "sodium glutamate")),
    "disodium inosinate": IngredientRecord(
        score=7, category="inflammatory",
        reason="Often used alongside MSG; may compound inflammatory effects",
        is_additive=True, aliases=("e631",)),
    "disodium guanylate": IngredientRecord(
        score=7, category="inflammatory",
        reason="Flavor enhancer often used with MSG",
        is_additive=True, aliases=("e627",)),
    "yeast extract": IngredientRecord(
        score=7, category="inflammatory",
        reason="Contains free glutamate similar to MSG",
        is_additive=True, aliases=("autolyzed yeast extract", "autolyzed yeast",
                                    "hydrolyzed yeast")),
    "natural flavors": IngredientRecord(
        score=5, category="neutral",
        reason="Broad category; generally neutral but composition varies",
        is_additive=True, aliases=("natural flavor", "natural flavoring", "natural flavourings")),
    "artificial flavors": IngredientRecord(
        score=7, category="inflammatory",
        reason="Synthetic chemical compounds that may trigger inflammatory responses",
        is_additive=True, aliases=("artificial flavor", "artificial flavoring")),
    "smoke flavor": IngredientRecord(
        score=6, category="neutral",
        reason="May contain polycyclic aromatic hydrocarbons in some forms",
        is_additive=True, aliases=("natural smoke flavor", "liquid smoke")),
    "hydrolyzed protein": IngredientRecord(
        score=7, category="inflammatory",
        reason="Contains free glutamate; processed protein with potential inflammatory effects",
        is_additive=True, aliases=("hydrolyzed vegetable protein", "hvp",
                                    "hydrolyzed soy protein", "hydrolyzed corn protein")),
    "maltol": IngredientRecord(
        score=6, category="neutral",
        reason="Flavor enhancer; limited inflammatory evidence",
        is_additive=True, aliases=("ethyl maltol", "e636", "e637")),
    "diacetyl": IngredientRecord(
        score=8, category="inflammatory",
        reason="Butter flavoring linked to lung inflammation when inhaled; limited oral data",
        is_additive=True, aliases=()),
    "vanillin": IngredientRecord(
        score=5, category="neutral",
        reason="Synthetic vanilla flavor; generally well-tolerated",
        is_additive=True, aliases=("ethyl vanillin",)),
    "nucleotides": IngredientRecord(
        score=5, category="neutral",
        reason="Flavor enhancers naturally found in many foods",
        is_additive=True, aliases=("disodium 5-ribonucleotides", "e635")),
    "worcestershire": IngredientRecord(
        score=5, category="neutral",
        reason="Fermented condiment; contains some beneficial compounds",
        is_additive=False, aliases=("worcestershire sauce",)),
    "soy sauce": IngredientRecord(
        score=5, category="neutral",
        reason="Fermented condiment; high in sodium but contains some isoflavones",
        is_additive=False, aliases=("tamari", "shoyu")),
    "fish sauce": IngredientRecord(
        score=5, category="neutral",
        reason="Fermented condiment; high sodium but contains amino acids",
        is_additive=False, aliases=()),

    # ── Acids & Leavening (20) ────────────────────────────────────────────

    "baking soda": IngredientRecord(
        score=5, category="neutral",
        reason="Sodium bicarbonate; neutral pH-adjusting leavening agent",
        is_additive=True, aliases=("sodium bicarbonate", "e500")),
    "baking powder": IngredientRecord(
        score=5, category="neutral",
        reason="Leavening agent combination; generally non-inflammatory",
        is_additive=True, aliases=()),
    "cream of tartar": IngredientRecord(
        score=5, category="neutral",
        reason="Natural acid from wine production",
        is_additive=True, aliases=("potassium bitartrate", "e336")),
    "sodium acid pyrophosphate": IngredientRecord(
        score=6, category="neutral",
        reason="Leavening acid; phosphate-based, moderate concerns at high intake",
        is_additive=True, aliases=("sapp", "e450")),
    "monocalcium phosphate": IngredientRecord(
        score=5, category="neutral",
        reason="Leavening agent; provides some calcium",
        is_additive=True, aliases=("e341",)),
    "sodium aluminum phosphate": IngredientRecord(
        score=7, category="inflammatory",
        reason="Contains aluminum which may promote neuroinflammation",
        is_additive=True, aliases=("e541",)),
    "ammonium bicarbonate": IngredientRecord(
        score=5, category="neutral",
        reason="Leavening agent that fully decomposes during baking",
        is_additive=True, aliases=("e503",)),
    "glucono delta lactone": IngredientRecord(
        score=5, category="neutral",
        reason="Acidifier naturally produced by glucose oxidation",
        is_additive=True, aliases=("gdl", "e575")),
    "fumaric acid": IngredientRecord(
        score=5, category="neutral",
        reason="Naturally occurring acid used as acidulant",
        is_additive=True, aliases=("e297",)),
    "adipic acid": IngredientRecord(
        score=5, category="neutral",
        reason="Acidulant used in gelatin desserts",
        is_additive=True, aliases=("e355",)),
    "sodium citrate": IngredientRecord(
        score=5, category="neutral",
        reason="Buffer and emulsifier derived from citric acid",
        is_additive=True, aliases=("trisodium citrate", "e331")),
    "calcium citrate": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Calcium supplement form with good bioavailability",
        is_additive=True, aliases=("e333",)),
    "potassium citrate": IngredientRecord(
        score=5, category="neutral",
        reason="Buffer and acidity regulator",
        is_additive=True, aliases=("e332",)),
    "calcium carbonate": IngredientRecord(
        score=5, category="neutral",
        reason="Calcium source and acidity regulator",
        is_additive=True, aliases=("e170",)),
    "magnesium carbonate": IngredientRecord(
        score=5, category="neutral",
        reason="Anti-caking agent and acidity regulator",
        is_additive=True, aliases=("e504",)),
    "potassium carbonate": IngredientRecord(
        score=5, category="neutral",
        reason="Acidity regulator used in Dutch-process cocoa",
        is_additive=True, aliases=("e501",)),
    "calcium sulfate": IngredientRecord(
        score=5, category="neutral",
        reason="Firming agent and calcium source (tofu coagulant)",
        is_additive=True, aliases=("e516", "gypsum")),
    "magnesium chloride": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Magnesium source with potential anti-inflammatory effects",
        is_additive=True, aliases=("e511", "nigari")),
    "calcium chloride": IngredientRecord(
        score=5, category="neutral",
        reason="Firming agent used in canning; generally non-inflammatory",
        is_additive=True, aliases=("e509",)),
    "sodium phosphate": IngredientRecord(
        score=6, category="neutral",
        reason="Emulsifier and leavening; excess phosphate intake may be pro-inflammatory",
        is_additive=True, aliases=("e339", "disodium phosphate", "trisodium phosphate")),

    # ── Nuts & Seeds (20) ─────────────────────────────────────────────────

    "almonds": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in vitamin E, magnesium, and anti-inflammatory monounsaturated fats",
        is_additive=False, aliases=("almond", "almond butter", "almond flour")),
    "walnuts": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Best nut source of anti-inflammatory omega-3 ALA",
        is_additive=False, aliases=("walnut",)),
    "chia seeds": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Excellent source of omega-3 ALA and anti-inflammatory fiber",
        is_additive=False, aliases=("chia", "chia seed")),
    "flaxseeds": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in omega-3 ALA and anti-inflammatory lignans",
        is_additive=False, aliases=("flax seeds", "flaxseed", "flax", "ground flaxseed",
                                     "flax meal", "linseed")),
    "hemp seeds": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Good omega-3 to omega-6 ratio with GLA",
        is_additive=False, aliases=("hemp hearts", "hemp seed")),
    "pumpkin seeds": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in magnesium and anti-inflammatory phytosterols",
        is_additive=False, aliases=("pepitas", "pumpkin seed")),
    "sunflower seeds": IngredientRecord(
        score=5, category="neutral",
        reason="Good vitamin E source but high in omega-6",
        is_additive=False, aliases=("sunflower seed", "sunflower seed kernels")),
    "sesame seeds": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains sesamin and sesamol with anti-inflammatory properties",
        is_additive=False, aliases=("sesame", "sesame seed", "tahini")),
    "cashews": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Good source of magnesium and zinc",
        is_additive=False, aliases=("cashew", "cashew butter")),
    "pistachios": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in anti-inflammatory antioxidants and lutein",
        is_additive=False, aliases=("pistachio",)),
    "pecans": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in anti-inflammatory polyphenols and vitamin E",
        is_additive=False, aliases=("pecan",)),
    "macadamia nuts": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Highest monounsaturated fat content among nuts",
        is_additive=False, aliases=("macadamia",)),
    "brazil nuts": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Excellent source of anti-inflammatory selenium",
        is_additive=False, aliases=("brazil nut",)),
    "hazelnuts": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in oleic acid and anti-inflammatory proanthocyanidins",
        is_additive=False, aliases=("hazelnut", "filbert")),
    "pine nuts": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains pinolenic acid with potential anti-inflammatory effects",
        is_additive=False, aliases=("pine nut", "pignoli")),
    "coconut": IngredientRecord(
        score=5, category="neutral",
        reason="Contains lauric acid; mixed effects on inflammation",
        is_additive=False, aliases=("coconut flakes", "shredded coconut",
                                     "desiccated coconut", "coconut flour")),
    "peanuts": IngredientRecord(
        score=5, category="neutral",
        reason="Contain resveratrol but also omega-6; moderate inflammatory profile",
        is_additive=False, aliases=("peanut", "peanut butter", "peanut flour")),
    "poppy seeds": IngredientRecord(
        score=5, category="neutral",
        reason="Contain some minerals; neutral inflammatory profile",
        is_additive=False, aliases=("poppy seed",)),
    "sacha inchi": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Very high in omega-3 ALA",
        is_additive=False, aliases=("sacha inchi seeds",)),
    "watermelon seeds": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Good source of magnesium and zinc",
        is_additive=False, aliases=()),

    # ── Legumes (15) ──────────────────────────────────────────────────────

    "lentils": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in fiber and polyphenols with anti-inflammatory effects",
        is_additive=False, aliases=("lentil", "red lentils", "green lentils")),
    "chickpeas": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Good source of fiber, folate, and anti-inflammatory saponins",
        is_additive=False, aliases=("garbanzo beans", "chickpea", "garbanzo")),
    "black beans": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in anti-inflammatory anthocyanins and fiber",
        is_additive=False, aliases=("black bean",)),
    "kidney beans": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in fiber and antioxidant anthocyanins",
        is_additive=False, aliases=("red kidney beans",)),
    "navy beans": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="High in fiber and ferulic acid",
        is_additive=False, aliases=("white beans", "great northern beans")),
    "pinto beans": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Good source of fiber and kaempferol",
        is_additive=False, aliases=("pinto bean",)),
    "soybeans": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Contains isoflavones with mild anti-inflammatory effects",
        is_additive=False, aliases=("soybean", "edamame", "soya")),
    "lima beans": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Good source of fiber and molybdenum",
        is_additive=False, aliases=("butter beans",)),
    "mung beans": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in vitexin and isovitexin with anti-inflammatory effects",
        is_additive=False, aliases=("mung bean", "moong")),
    "adzuki beans": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in polyphenols with anti-inflammatory properties",
        is_additive=False, aliases=("azuki beans",)),
    "split peas": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="High in fiber and anti-inflammatory isoflavones",
        is_additive=False, aliases=("split pea", "yellow split peas")),
    "lupini beans": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="High protein legume with anti-inflammatory alkaloids",
        is_additive=False, aliases=("lupin", "lupini")),
    "fava beans": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Rich in L-DOPA and anti-inflammatory compounds",
        is_additive=False, aliases=("broad beans", "faba beans")),
    "tempeh": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Fermented soy with enhanced anti-inflammatory isoflavones and probiotics",
        is_additive=False, aliases=()),
    "tofu": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Soy product with isoflavones; mild anti-inflammatory",
        is_additive=False, aliases=("bean curd",)),

    # ── Common Terms (30) ─────────────────────────────────────────────────

    "water": IngredientRecord(
        score=5, category="neutral",
        reason="Essential and neutral",
        is_additive=False, aliases=("purified water", "filtered water", "spring water",
                                     "distilled water", "carbonated water")),
    "salt": IngredientRecord(
        score=6, category="neutral",
        reason="Excess sodium may promote inflammation, but moderate amounts are essential",
        is_additive=False, aliases=("sodium chloride", "sea salt", "himalayan salt",
                                     "kosher salt", "iodized salt", "table salt")),
    "vinegar": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Acetic acid may have mild anti-inflammatory and blood sugar lowering effects",
        is_additive=False, aliases=("apple cider vinegar", "distilled vinegar",
                                     "white vinegar", "wine vinegar", "balsamic vinegar",
                                     "rice vinegar")),
    "yeast": IngredientRecord(
        score=5, category="neutral",
        reason="Leavening agent; generally non-inflammatory",
        is_additive=False, aliases=("active dry yeast", "baker's yeast",
                                     "nutritional yeast", "brewers yeast")),
    "niacin": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Vitamin B3 with anti-inflammatory effects",
        is_additive=True, aliases=("niacinamide", "vitamin b3", "nicotinic acid")),
    "thiamine": IngredientRecord(
        score=5, category="neutral",
        reason="Vitamin B1; essential nutrient with neutral inflammatory effect",
        is_additive=True, aliases=("thiamine mononitrate", "thiamin", "vitamin b1")),
    "riboflavin": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Vitamin B2 with mild anti-inflammatory effects",
        is_additive=True, aliases=("vitamin b2",)),
    "folic acid": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="B vitamin that helps reduce homocysteine-related inflammation",
        is_additive=True, aliases=("folate", "vitamin b9")),
    "iron": IngredientRecord(
        score=5, category="neutral",
        reason="Essential mineral; excess can be pro-oxidant",
        is_additive=True, aliases=("reduced iron", "ferrous sulfate",
                                    "ferrous fumarate", "iron oxide")),
    "zinc": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Essential mineral with anti-inflammatory immune-modulating effects",
        is_additive=True, aliases=("zinc oxide", "zinc gluconate", "zinc sulfate")),
    "calcium": IngredientRecord(
        score=5, category="neutral",
        reason="Essential mineral for bones; neutral inflammatory effect",
        is_additive=True, aliases=("calcium phosphate", "tricalcium phosphate")),
    "magnesium": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Essential mineral; low magnesium is associated with increased inflammation",
        is_additive=True, aliases=("magnesium oxide", "magnesium citrate")),
    "potassium": IngredientRecord(
        score=5, category="neutral",
        reason="Essential mineral for heart and nerve function",
        is_additive=True, aliases=("potassium chloride",)),
    "vitamin d": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Potent immune modulator with anti-inflammatory effects",
        is_additive=True, aliases=("cholecalciferol", "vitamin d3", "ergocalciferol",
                                    "vitamin d2")),
    "vitamin a": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Supports immune function with mild anti-inflammatory effects",
        is_additive=True, aliases=("retinol", "retinyl palmitate", "beta-carotene")),
    "vitamin k": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Helps regulate inflammatory responses",
        is_additive=True, aliases=("vitamin k1", "vitamin k2", "phylloquinone",
                                    "menaquinone")),
    "omega-3": IngredientRecord(
        score=1, category="highly_anti_inflammatory",
        reason="EPA and DHA are among the most potent natural anti-inflammatory compounds",
        is_additive=False, aliases=("omega 3", "epa", "dha", "omega-3 fatty acids")),
    "inulin": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Prebiotic fiber that supports anti-inflammatory gut bacteria",
        is_additive=True, aliases=("chicory root fiber", "chicory root extract")),
    "psyllium": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Soluble fiber with demonstrated anti-inflammatory effects",
        is_additive=True, aliases=("psyllium husk", "psyllium fiber")),
    "apple cider vinegar": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains acetic acid and polyphenols with anti-inflammatory properties",
        is_additive=False, aliases=()),
    "wheatgrass": IngredientRecord(
        score=2, category="highly_anti_inflammatory",
        reason="Rich in chlorophyll and anti-inflammatory flavonoids",
        is_additive=False, aliases=("wheat grass", "wheatgrass powder")),
    "aloe vera": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains acemannan with anti-inflammatory and immune-modulating effects",
        is_additive=False, aliases=("aloe", "aloe vera gel")),
    "caffeine": IngredientRecord(
        score=5, category="neutral",
        reason="Mild stimulant; moderate amounts may have anti-inflammatory effects",
        is_additive=True, aliases=()),
    "coffee": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Rich in chlorogenic acid and other anti-inflammatory polyphenols",
        is_additive=False, aliases=("coffee extract", "coffee bean")),
    "tea": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains catechins and theaflavins with anti-inflammatory effects",
        is_additive=False, aliases=("black tea", "tea extract")),
    "probiotics": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Beneficial bacteria that support gut health and reduce inflammation",
        is_additive=True, aliases=("lactobacillus", "bifidobacterium", "probiotic cultures",
                                    "live cultures", "active cultures")),
    "fiber": IngredientRecord(
        score=4, category="anti_inflammatory",
        reason="Dietary fiber supports gut health and reduces systemic inflammation",
        is_additive=False, aliases=("dietary fiber", "soluble fiber")),
    "colostrum": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains immunoglobulins and growth factors with anti-inflammatory properties",
        is_additive=False, aliases=("bovine colostrum",)),
    "bone broth": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Contains glycine and proline which may reduce inflammation",
        is_additive=False, aliases=("bone broth powder",)),
    "sauerkraut": IngredientRecord(
        score=3, category="anti_inflammatory",
        reason="Fermented food rich in probiotics and anti-inflammatory compounds",
        is_additive=False, aliases=()),
}

# ═══════════════════════════════════════════════════════════════════════════
# ALIAS INDEX (built at import time for O(1) lookup)
# ═══════════════════════════════════════════════════════════════════════════

_ALIAS_INDEX: Dict[str, IngredientRecord] = {}


def _build_alias_index() -> None:
    """Build reverse index from all aliases to their IngredientRecord."""
    for name, record in INGREDIENT_DATABASE.items():
        key = name.lower().strip()
        _ALIAS_INDEX[key] = record
        for alias in record.aliases:
            alias_key = alias.lower().strip()
            if alias_key not in _ALIAS_INDEX:
                _ALIAS_INDEX[alias_key] = record


_build_alias_index()


def get_by_name(name: str) -> Optional[IngredientRecord]:
    """Look up an ingredient by exact name or alias. O(1)."""
    return _ALIAS_INDEX.get(name.lower().strip())


def get_alias_index() -> Dict[str, IngredientRecord]:
    """Return the alias index for substring/fuzzy matching."""
    return _ALIAS_INDEX
