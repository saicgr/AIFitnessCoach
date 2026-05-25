-- 2100_equipment_inventory.sql
-- Phase 1 of the workouts overhaul: per-user equipment calibration so plate math
-- matches reality (Reddit insight: "I told it my EZ bar is 17.5lb. Now the plate
-- suggestions actually work.").
--
-- Each user can have multiple equipment_inventory rows; each row optionally
-- references the canonical equipment_types registry but carries the user-specific
-- calibration the workout generator and active-workout plate visualizer consult.
--
-- Replaces: hardcoded const lists in barbell_plate_indicator.dart and
-- percentage_training_service_helpers.WEIGHT_INCREMENTS as primary source of
-- truth (kept as fallback when no row matches).

CREATE TABLE IF NOT EXISTS equipment_inventory (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  equipment_type_id        uuid REFERENCES equipment_types(id) ON DELETE SET NULL,
  label                    text,
  category                 text CHECK (category IN ('barbell','dumbbell','cable','machine','plate_set','kettlebell','other')),
  bar_empty_weight_kg      numeric,
  machine_empty_weight_kg  numeric,
  cable_pin_start_kg       numeric,
  cable_pin_increment_kg   numeric,
  plate_inventory          jsonb,
  dumbbell_inventory       jsonb,
  weight_unit              text NOT NULL DEFAULT 'kg' CHECK (weight_unit IN ('kg','lb')),
  count                    int  NOT NULL DEFAULT 1,
  notes                    text,
  created_at               timestamptz NOT NULL DEFAULT now(),
  updated_at               timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_equipment_inventory_user           ON equipment_inventory(user_id);
CREATE INDEX IF NOT EXISTS idx_equipment_inventory_user_category  ON equipment_inventory(user_id, category);
CREATE INDEX IF NOT EXISTS idx_equipment_inventory_type           ON equipment_inventory(equipment_type_id);

ALTER TABLE equipment_inventory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS equipment_inventory_user_isolated ON equipment_inventory;
CREATE POLICY equipment_inventory_user_isolated ON equipment_inventory
  FOR ALL
  USING      (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.set_equipment_inventory_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_equipment_inventory_updated_at ON equipment_inventory;
CREATE TRIGGER trg_equipment_inventory_updated_at
  BEFORE UPDATE ON equipment_inventory
  FOR EACH ROW
  EXECUTE FUNCTION public.set_equipment_inventory_updated_at();

COMMENT ON TABLE  equipment_inventory IS
  'Per-user equipment with calibration fields (bar weight, machine sled, cable pin start/increment, plate/dumbbell inventory). Consumed by percentage_training_service_helpers + barbell_plate_indicator.dart. Phase 1 of workouts overhaul.';
COMMENT ON COLUMN equipment_inventory.bar_empty_weight_kg     IS 'Empty weight of THIS bar (overrides const tables). 7.94kg/17.5lb EZ curl, 20kg/45lb Olympic, etc.';
COMMENT ON COLUMN equipment_inventory.machine_empty_weight_kg IS 'Carriage/sled empty weight included in total. Leg-press +45lb sled is the canonical example.';
COMMENT ON COLUMN equipment_inventory.cable_pin_start_kg      IS 'Starting pin weight on this cable machine (e.g. 9kg/20lb).';
COMMENT ON COLUMN equipment_inventory.cable_pin_increment_kg  IS 'Pin increment for this cable machine; falls back to global weight_increments if null.';
COMMENT ON COLUMN equipment_inventory.plate_inventory         IS 'JSON map of plate weight -> count, e.g. {"45": 4, "25": 4, "10": 2, "5": 2}. Units per weight_unit.';
COMMENT ON COLUMN equipment_inventory.dumbbell_inventory      IS 'JSON map of dumbbell weight -> count, e.g. {"20": 2, "25": 2, "30": 1}.';
