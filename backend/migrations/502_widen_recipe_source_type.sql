-- Migration: 502_widen_recipe_source_type.sql
-- Description: Widen user_recipes.source_type to fit new import sources
--              (imported_text, imported_url, imported_handwritten, pantry_suggested,
--               cloned_from_share). VARCHAR(20) was too tight for 'imported_handwritten' (20)
--               with no headroom. New VARCHAR(40) keeps the column small but flexible.
-- Created: 2026-04-14

-- recipes_with_stats and popular_community_recipes both reference source_type;
-- drop and recreate around the column alter.

DROP VIEW IF EXISTS recipes_with_stats;
DROP VIEW IF EXISTS popular_community_recipes;

ALTER TABLE user_recipes
    ALTER COLUMN source_type TYPE VARCHAR(40);

CREATE OR REPLACE VIEW recipes_with_stats AS
SELECT r.id,
       r.user_id,
       r.name,
       r.description,
       r.servings,
       r.prep_time_minutes,
       r.cook_time_minutes,
       r.instructions,
       r.image_url,
       r.category,
       r.cuisine,
       r.tags,
       r.calories_per_serving,
       r.protein_per_serving_g,
       r.carbs_per_serving_g,
       r.fat_per_serving_g,
       r.fiber_per_serving_g,
       r.sugar_per_serving_g,
       r.vitamin_d_per_serving_iu,
       r.calcium_per_serving_mg,
       r.iron_per_serving_mg,
       r.omega3_per_serving_g,
       r.sodium_per_serving_mg,
       r.micronutrients_per_serving,
       r.times_logged,
       r.last_logged_at,
       r.source_url,
       r.source_type,
       r.is_public,
       r.shared_with_community,
       r.created_at,
       r.updated_at,
       r.deleted_at,
       count(ri.id) AS ingredient_count,
       COALESCE(r.prep_time_minutes, 0) + COALESCE(r.cook_time_minutes, 0) AS total_time_minutes
  FROM user_recipes r
  LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
 WHERE r.deleted_at IS NULL
 GROUP BY r.id;

CREATE OR REPLACE VIEW popular_community_recipes AS
SELECT id, user_id, name, description, servings, prep_time_minutes, cook_time_minutes,
       instructions, image_url, category, cuisine, tags,
       calories_per_serving, protein_per_serving_g, carbs_per_serving_g, fat_per_serving_g,
       fiber_per_serving_g, sugar_per_serving_g,
       vitamin_d_per_serving_iu, calcium_per_serving_mg, iron_per_serving_mg,
       omega3_per_serving_g, sodium_per_serving_mg, micronutrients_per_serving,
       times_logged, last_logged_at, source_url, source_type,
       is_public, shared_with_community, created_at, updated_at, deleted_at
  FROM user_recipes
 WHERE is_public = TRUE AND deleted_at IS NULL
 ORDER BY times_logged DESC, created_at DESC
 LIMIT 100;

COMMENT ON COLUMN user_recipes.source_type IS
    'Recipe origin: manual | ai_generated | imported_text | imported_url | imported_handwritten | pantry_suggested | cloned_from_share';
