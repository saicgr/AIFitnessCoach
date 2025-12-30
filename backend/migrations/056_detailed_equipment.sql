-- Migration: Add detailed equipment with quantities and weights
-- This allows users to specify equipment with quantities and weight ranges

-- Add a new column for detailed equipment info
-- The existing 'equipment' column (VARCHAR) stores simple equipment names as JSON array: ["dumbbells", "barbell"]
-- The new 'equipment_details' column stores detailed info as JSONB:
-- [
--   {"name": "dumbbells", "quantity": 2, "weights": [15, 25, 40], "weight_unit": "lbs", "notes": "Hex dumbbells"},
--   {"name": "kettlebells", "quantity": 1, "weights": [25], "weight_unit": "lbs"},
--   {"name": "pull_up_bar", "quantity": 1, "weights": [], "weight_unit": "lbs", "notes": "Doorframe mounted"}
-- ]

ALTER TABLE users
ADD COLUMN IF NOT EXISTS equipment_details JSONB DEFAULT '[]';

-- Add index for efficient querying of equipment details
CREATE INDEX IF NOT EXISTS idx_users_equipment_details
ON users USING GIN (equipment_details);

-- Add comment for documentation
COMMENT ON COLUMN users.equipment_details IS
'Detailed equipment info with quantities and weights. Array of objects with: name (string), quantity (int), weights (array of numbers), weight_unit (lbs/kg), notes (optional string)';

-- Create a function to extract simple equipment names from detailed equipment
-- This can be used for backwards compatibility
CREATE OR REPLACE FUNCTION get_equipment_names(equipment_details JSONB)
RETURNS TEXT[] AS $$
BEGIN
  IF equipment_details IS NULL OR equipment_details = '[]'::jsonb THEN
    RETURN ARRAY[]::TEXT[];
  END IF;

  RETURN ARRAY(
    SELECT jsonb_array_elements_text(
      jsonb_path_query_array(equipment_details, '$[*].name')
    )
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER
SET search_path = public;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_equipment_names(JSONB) TO authenticated;
