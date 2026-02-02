-- Migration 209: Food Analysis Caching System
-- Adds caching tables to dramatically speed up food logging (100s -> <2s for repeated queries)

-- ============================================================================
-- Table 1: food_analysis_cache
-- Caches Gemini AI responses for food descriptions
-- ============================================================================
CREATE TABLE IF NOT EXISTS food_analysis_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Cache key: SHA256 hash of normalized food description
    query_hash TEXT UNIQUE NOT NULL,

    -- Original food description (for debugging/verification)
    food_description TEXT NOT NULL,

    -- Full Gemini response stored as JSONB
    -- Includes: food_items, calories, protein, carbs, fat, micronutrients, etc.
    analysis_result JSONB NOT NULL,

    -- Cache metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    hit_count INT DEFAULT 1,

    -- Source tracking (for cache invalidation if needed)
    model_version TEXT DEFAULT 'gemini-2.0-flash',
    prompt_version TEXT DEFAULT 'v1'
);

-- Index for fast hash lookups
CREATE INDEX IF NOT EXISTS idx_food_cache_hash ON food_analysis_cache(query_hash);

-- Index for cache cleanup (old entries)
CREATE INDEX IF NOT EXISTS idx_food_cache_created ON food_analysis_cache(created_at);

-- ============================================================================
-- Table 2: common_foods
-- Pre-computed nutrition for frequently logged foods (bypasses AI entirely)
-- ============================================================================
CREATE TABLE IF NOT EXISTS common_foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Primary name (canonical form)
    name TEXT NOT NULL,

    -- Alternative names for fuzzy matching
    -- e.g., ["biryani", "lamb biryani", "mutton biryani", "gosht biryani"]
    aliases TEXT[] DEFAULT '{}',

    -- Default serving info
    serving_size TEXT DEFAULT '1 serving',
    serving_weight_g DECIMAL,

    -- Macronutrients (per serving)
    calories INT NOT NULL,
    protein_g DECIMAL NOT NULL,
    carbs_g DECIMAL NOT NULL,
    fat_g DECIMAL NOT NULL,
    fiber_g DECIMAL DEFAULT 0,

    -- Full micronutrients (optional, stored as JSONB)
    micronutrients JSONB DEFAULT '{}',

    -- Data source for transparency
    source TEXT DEFAULT 'ai_verified',  -- 'usda', 'manual', 'ai_verified'

    -- Category for organization
    category TEXT,  -- 'indian', 'american', 'fruit', 'vegetable', etc.

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Index for name search
CREATE INDEX IF NOT EXISTS idx_common_foods_name ON common_foods(LOWER(name));

-- GIN index for alias array search
CREATE INDEX IF NOT EXISTS idx_common_foods_aliases ON common_foods USING GIN(aliases);

-- Index for category filtering
CREATE INDEX IF NOT EXISTS idx_common_foods_category ON common_foods(category);

-- ============================================================================
-- Table 3: rag_context_cache
-- Caches RAG context by user goal hash (goals don't change often)
-- ============================================================================
CREATE TABLE IF NOT EXISTS rag_context_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Cache key: hash of user goals/nutrition preferences
    goal_hash TEXT UNIQUE NOT NULL,

    -- Cached RAG context (documents + embeddings info)
    context_result JSONB NOT NULL,

    -- Cache metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    hit_count INT DEFAULT 1,

    -- TTL hint (1 hour for goals, they can change)
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '1 hour')
);

-- Index for hash lookups
CREATE INDEX IF NOT EXISTS idx_rag_cache_hash ON rag_context_cache(goal_hash);

-- Index for expiry cleanup
CREATE INDEX IF NOT EXISTS idx_rag_cache_expires ON rag_context_cache(expires_at);

-- ============================================================================
-- Helper function: Update hit count and last_accessed_at on cache hit
-- ============================================================================
CREATE OR REPLACE FUNCTION update_cache_hit_stats()
RETURNS TRIGGER AS $$
BEGIN
    NEW.hit_count := OLD.hit_count + 1;
    NEW.last_accessed_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RLS Policies (cache tables are service-only, no user access needed)
-- ============================================================================
ALTER TABLE food_analysis_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE common_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE rag_context_cache ENABLE ROW LEVEL SECURITY;

-- Service role can do everything
CREATE POLICY "Service role full access to food_analysis_cache"
ON food_analysis_cache FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Service role full access to common_foods"
ON common_foods FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Service role full access to rag_context_cache"
ON rag_context_cache FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Authenticated users can read common_foods (for client-side search)
CREATE POLICY "Authenticated users can read common_foods"
ON common_foods FOR SELECT
TO authenticated
USING (is_active = TRUE);

-- ============================================================================
-- Seed common foods with accurate nutrition data
-- Focus on frequently logged items and regional foods
-- ============================================================================
INSERT INTO common_foods (name, aliases, serving_size, serving_weight_g, calories, protein_g, carbs_g, fat_g, fiber_g, category, source) VALUES
-- Indian Foods
('Chicken Biryani', ARRAY['biryani', 'chicken biryani', 'hyderabadi biryani'], '1 plate', 350, 550, 28, 65, 18, 3, 'indian', 'ai_verified'),
('Lamb Biryani', ARRAY['mutton biryani', 'gosht biryani', 'lamb biryani'], '1 plate', 350, 650, 32, 60, 28, 3, 'indian', 'ai_verified'),
('Dal Tadka', ARRAY['dal', 'yellow dal', 'toor dal', 'dal fry'], '1 bowl', 200, 180, 12, 25, 4, 8, 'indian', 'ai_verified'),
('Butter Chicken', ARRAY['murgh makhani', 'chicken makhani'], '1 serving', 250, 450, 35, 12, 30, 2, 'indian', 'ai_verified'),
('Naan', ARRAY['naan bread', 'tandoori naan', 'garlic naan'], '1 piece', 90, 260, 8, 45, 5, 2, 'indian', 'ai_verified'),
('Roti', ARRAY['chapati', 'phulka', 'whole wheat roti'], '1 piece', 40, 100, 3, 18, 1, 2, 'indian', 'ai_verified'),
('Paneer Tikka', ARRAY['paneer tikka masala', 'tandoori paneer'], '1 serving', 200, 350, 20, 10, 26, 2, 'indian', 'ai_verified'),
('Samosa', ARRAY['vegetable samosa', 'aloo samosa'], '1 piece', 80, 250, 5, 30, 12, 2, 'indian', 'ai_verified'),
('Idli', ARRAY['steamed idli', 'rice idli'], '2 pieces', 100, 140, 4, 28, 1, 1, 'indian', 'ai_verified'),
('Dosa', ARRAY['masala dosa', 'plain dosa', 'crispy dosa'], '1 piece', 150, 200, 5, 30, 8, 2, 'indian', 'ai_verified'),

-- American/Western Foods
('Grilled Chicken Breast', ARRAY['chicken breast', 'boneless chicken', 'plain chicken'], '1 breast', 170, 280, 53, 0, 6, 0, 'protein', 'usda'),
('Scrambled Eggs', ARRAY['eggs', 'egg scramble', '2 eggs scrambled'], '2 eggs', 120, 180, 12, 2, 13, 0, 'protein', 'usda'),
('Oatmeal', ARRAY['oats', 'porridge', 'rolled oats', 'steel cut oats'], '1 cup cooked', 240, 150, 5, 27, 3, 4, 'grain', 'usda'),
('Brown Rice', ARRAY['rice', 'cooked rice', 'steamed rice'], '1 cup cooked', 195, 215, 5, 45, 2, 4, 'grain', 'usda'),
('White Rice', ARRAY['plain rice', 'basmati rice', 'jasmine rice'], '1 cup cooked', 185, 205, 4, 45, 0, 1, 'grain', 'usda'),
('Salmon Fillet', ARRAY['grilled salmon', 'baked salmon', 'salmon'], '1 fillet', 180, 350, 40, 0, 20, 0, 'protein', 'usda'),
('Greek Yogurt', ARRAY['yogurt', 'plain yogurt', 'low fat yogurt'], '1 cup', 245, 130, 17, 8, 0, 0, 'dairy', 'usda'),
('Avocado', ARRAY['whole avocado', 'fresh avocado'], '1 medium', 150, 240, 3, 12, 22, 10, 'fruit', 'usda'),
('Banana', ARRAY['ripe banana', 'fresh banana'], '1 medium', 118, 105, 1, 27, 0, 3, 'fruit', 'usda'),
('Apple', ARRAY['fresh apple', 'red apple', 'green apple'], '1 medium', 182, 95, 0, 25, 0, 4, 'fruit', 'usda'),

-- Protein Sources
('Whey Protein Shake', ARRAY['protein shake', 'whey shake', 'post workout shake'], '1 scoop', 30, 120, 24, 3, 1, 0, 'supplement', 'ai_verified'),
('Chicken Thigh', ARRAY['bone-in chicken', 'chicken leg'], '1 thigh', 115, 210, 26, 0, 11, 0, 'protein', 'usda'),
('Ground Beef', ARRAY['minced beef', 'beef mince', '80/20 beef'], '100g', 100, 250, 17, 0, 20, 0, 'protein', 'usda'),
('Tofu', ARRAY['firm tofu', 'bean curd'], '100g', 100, 145, 17, 4, 8, 2, 'protein', 'usda'),
('Lentils', ARRAY['cooked lentils', 'masoor dal', 'red lentils'], '1 cup cooked', 198, 230, 18, 40, 1, 16, 'legume', 'usda'),
('Chickpeas', ARRAY['garbanzo beans', 'chole', 'chana'], '1 cup cooked', 164, 270, 15, 45, 4, 12, 'legume', 'usda'),

-- Vegetables
('Broccoli', ARRAY['steamed broccoli', 'fresh broccoli'], '1 cup', 91, 55, 4, 11, 1, 5, 'vegetable', 'usda'),
('Spinach', ARRAY['fresh spinach', 'baby spinach', 'palak'], '1 cup raw', 30, 7, 1, 1, 0, 1, 'vegetable', 'usda'),
('Sweet Potato', ARRAY['baked sweet potato', 'yam'], '1 medium', 130, 115, 2, 27, 0, 4, 'vegetable', 'usda'),

-- Common Meals
('Protein Bowl', ARRAY['chicken rice bowl', 'macro bowl'], '1 bowl', 400, 500, 40, 45, 15, 5, 'meal', 'ai_verified'),
('Caesar Salad', ARRAY['chicken caesar', 'caesar with chicken'], '1 serving', 300, 400, 25, 15, 28, 4, 'salad', 'ai_verified'),
('Burrito Bowl', ARRAY['chipotle bowl', 'mexican bowl'], '1 bowl', 450, 650, 35, 70, 25, 12, 'mexican', 'ai_verified'),
('Poke Bowl', ARRAY['ahi poke', 'salmon poke', 'tuna bowl'], '1 bowl', 350, 450, 30, 50, 12, 5, 'asian', 'ai_verified'),

-- Snacks
('Almonds', ARRAY['raw almonds', 'roasted almonds'], '1 oz (23 nuts)', 28, 165, 6, 6, 14, 4, 'nuts', 'usda'),
('Peanut Butter', ARRAY['natural peanut butter', 'pb'], '2 tbsp', 32, 190, 8, 6, 16, 2, 'nuts', 'usda'),
('Protein Bar', ARRAY['quest bar', 'rx bar', 'kind bar'], '1 bar', 60, 200, 20, 22, 8, 3, 'supplement', 'ai_verified'),

-- Beverages
('Black Coffee', ARRAY['coffee', 'americano', 'drip coffee'], '1 cup', 240, 5, 0, 0, 0, 0, 'beverage', 'usda'),
('Whole Milk', ARRAY['milk', 'full fat milk'], '1 cup', 244, 150, 8, 12, 8, 0, 'dairy', 'usda'),
('Orange Juice', ARRAY['fresh oj', 'orange juice'], '1 cup', 248, 110, 2, 26, 0, 0, 'beverage', 'usda')

ON CONFLICT DO NOTHING;

-- ============================================================================
-- Comments for documentation
-- ============================================================================
COMMENT ON TABLE food_analysis_cache IS 'Caches Gemini AI food analysis responses. Query hash is SHA256 of normalized food description.';
COMMENT ON TABLE common_foods IS 'Pre-computed nutrition data for common foods. Bypasses AI for instant lookups.';
COMMENT ON TABLE rag_context_cache IS 'Caches RAG context by user goal hash. 1-hour TTL since goals can change.';
COMMENT ON COLUMN food_analysis_cache.query_hash IS 'SHA256 hash of lowercase, trimmed, single-spaced food description';
COMMENT ON COLUMN common_foods.aliases IS 'Alternative names for fuzzy matching. Include regional variations.';
