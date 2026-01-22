-- Migration: 169_hyrox_race_prep.sql
-- Description: Add HYROX Race Prep program to branded_programs
-- Created: 2026-01-20

INSERT INTO branded_programs (
    name, tagline, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type, goals,
    icon_name, color_hex, is_featured, is_premium, requires_gym, minimum_equipment
) VALUES (
    'HYROX Race Prep',
    'Train for race day glory',
    'An intensive 12-week program designed specifically for HYROX competition. Combines running intervals with functional fitness workouts targeting all 8 HYROX stations: SkiErg, Sled Push, Sled Pull, Burpee Broad Jumps, Rowing, Farmers Carry, Sandbag Lunges, and Wall Balls. Progressive overload and race simulation workouts ensure you peak on race day.',
    'athletic',
    'advanced',
    12,
    5,
    'custom',
    ARRAY['hyrox_competition', 'race_prep', 'functional_fitness', 'endurance', 'strength_endurance'],
    'emoji_events',
    '#FF5722',
    true,
    true,
    true,
    ARRAY['skierg', 'rower', 'sled', 'sandbag', 'wall_ball', 'farmers_handles', 'running_track']
);
