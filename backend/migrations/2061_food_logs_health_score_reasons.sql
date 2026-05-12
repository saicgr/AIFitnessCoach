ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS health_score_reasons TEXT[];
COMMENT ON COLUMN food_logs.health_score_reasons IS
  'Tags emitted by Gemini meal-analysis OR derived locally — used by ScoreExplainSheet to show WHY a meal earned its health_score (e.g. high_protein, ultra_processed, deep_fried).';
