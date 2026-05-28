-- Migration 2203 — sleep_stories content catalog
-- Backs:
--   GET /api/v1/sleep-stories/today  (today's pick, rotation by DOY)

CREATE TABLE IF NOT EXISTS sleep_stories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug text UNIQUE NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    duration_min int NOT NULL,
    audio_url text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO sleep_stories (slug, title, description, duration_min, audio_url) VALUES
('lighthouse-keeper', 'The Lighthouse Keeper', 'A slow, low-stakes evening in a remote lighthouse — trimming the wick, watching fog roll in, listening to the foghorn answer the dark. 18 minutes of nothing dramatic happening, which is the point.', 18, 'https://zealova-content.s3.amazonaws.com/sleep-stories/lighthouse-keeper.mp3'),
('northern-cabin', 'Northern Cabin', 'You arrive at a small cabin in late winter. Snow on the eaves, woodstove already warm, no plans for tomorrow. The narration walks you through the rooms then settles by the fire.', 22, 'https://zealova-content.s3.amazonaws.com/sleep-stories/northern-cabin.mp3'),
('slow-tide', 'Slow Tide', 'A 15-minute account of an outgoing tide on a quiet coast. The voice describes shells, kelp, sand patterns, and the long shallow water — paced to match a slowing heartbeat.', 15, 'https://zealova-content.s3.amazonaws.com/sleep-stories/slow-tide.mp3'),
('the-old-library', 'The Old Library', 'A long evening alone in a wood-paneled library after closing. Lamps, leather chairs, dust motes, the smell of old books. No plot — just slow drift through the stacks.', 20, 'https://zealova-content.s3.amazonaws.com/sleep-stories/the-old-library.mp3'),
('train-through-mountains', 'Train Through the Mountains', 'You are on an overnight sleeper train threading through high country. Steady wheel rhythm, dim cabin light, occasional glimpses of moonlit pines. 24 minutes of gentle motion.', 24, 'https://zealova-content.s3.amazonaws.com/sleep-stories/train-through-mountains.mp3'),
('rain-on-a-cabin-roof', 'Rain on a Cabin Roof', 'Steady spring rain on a wooden roof. The narration is sparse — mostly the rain itself, with occasional descriptions of the cabin, the kettle on the stove, the open book on the table.', 22, 'https://zealova-content.s3.amazonaws.com/sleep-stories/rain-on-a-cabin-roof.mp3'),
('quiet-forest-at-dusk', 'Quiet Forest at Dusk', 'A walk through an old-growth forest as the light fades. Soft footsteps, distant birds settling, the sound of wind through high branches. 18 minutes, no destination.', 18, 'https://zealova-content.s3.amazonaws.com/sleep-stories/quiet-forest-at-dusk.mp3'),
('boat-on-a-calm-lake', 'Boat on a Calm Lake', 'A small wooden rowboat on glass-still water at the end of a long summer day. The narration describes the rod, the line, the surface of the lake — never the catch.', 15, 'https://zealova-content.s3.amazonaws.com/sleep-stories/boat-on-a-calm-lake.mp3'),
('greenhouse-in-winter', 'Greenhouse in Winter', 'You take shelter in a heated greenhouse on a snowy night. Glass roof, warm air, the smell of soil and tomato vines. The voice walks you slowly along each row of plants.', 20, 'https://zealova-content.s3.amazonaws.com/sleep-stories/greenhouse-in-winter.mp3'),
('mountain-snowfall', 'Mountain Snowfall', 'High-altitude snowfall after dark, watched from a windowed cabin. Heavy flakes, soft drifting, the muffled hush only deep snow creates. 12 minutes of stillness.', 12, 'https://zealova-content.s3.amazonaws.com/sleep-stories/mountain-snowfall.mp3')
ON CONFLICT (slug) DO NOTHING;
