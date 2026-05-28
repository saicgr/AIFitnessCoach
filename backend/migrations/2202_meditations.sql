-- Migration 2202 — meditations content catalog
-- Backs:
--   GET /api/v1/meditation/today  (today's pick, rotation by DOY)
-- Audio URLs point at zealova-content S3 bucket; files may upload later.

CREATE TABLE IF NOT EXISTS meditations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug text UNIQUE NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    duration_min int NOT NULL,
    audio_url text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO meditations (slug, title, description, duration_min, audio_url) VALUES
('pre-workout-focus-5', 'Pre-workout focus reset', 'Sharp 5-minute primer to clear mental clutter and lock in to your next set. Box breathing, intention setting, and a short body activation cue.', 5, 'https://zealova-content.s3.amazonaws.com/meditations/pre-workout-focus-5.mp3'),
('pre-workout-focus-8', 'Pre-lift sharpening', '8 minutes of guided breath and visualization for heavy lifting days. Rehearses cue points for your main lift before you touch the bar.', 8, 'https://zealova-content.s3.amazonaws.com/meditations/pre-workout-focus-8.mp3'),
('post-workout-cooldown-10', 'Post-workout cooldown', '10-minute parasympathetic switch — slow exhales, gentle body scan, and a reset of breathing rate so recovery starts the moment you rack.', 10, 'https://zealova-content.s3.amazonaws.com/meditations/post-workout-cooldown-10.mp3'),
('stress-release-10', 'Stress release', 'A 10-minute exhale-led practice for high-cortisol days. Designed to drop heart rate and unclench the jaw, shoulders, and stomach.', 10, 'https://zealova-content.s3.amazonaws.com/meditations/stress-release-10.mp3'),
('stress-release-15', 'Deep stress release', 'A 15-minute longer-form practice combining body scan, slow nasal breathing, and progressive muscle relaxation for hard days.', 15, 'https://zealova-content.s3.amazonaws.com/meditations/stress-release-15.mp3'),
('sleep-wind-down-10', 'Sleep wind-down', '10 minutes of guided slow breathing and tension release for the last hour before bed. Designed to shift the nervous system into rest mode.', 10, 'https://zealova-content.s3.amazonaws.com/meditations/sleep-wind-down-10.mp3'),
('sleep-wind-down-20', 'Long sleep wind-down', 'A 20-minute drift session that fades from guided breath into long silence so you can fall asleep inside the track.', 20, 'https://zealova-content.s3.amazonaws.com/meditations/sleep-wind-down-20.mp3'),
('gratitude-5', 'Quick gratitude', '5 minutes anchoring three concrete things from your last 24 hours. Short, no-fluff practice for busy mornings.', 5, 'https://zealova-content.s3.amazonaws.com/meditations/gratitude-5.mp3'),
('gratitude-10', 'Gratitude deep dive', '10 minutes of slower, more reflective gratitude — useful when motivation is low and you need to re-anchor why you train.', 10, 'https://zealova-content.s3.amazonaws.com/meditations/gratitude-10.mp3'),
('body-scan-10', 'Body scan', 'A 10-minute head-to-toe scan that lights up where tension lives. Useful after long sitting days or before a mobility session.', 10, 'https://zealova-content.s3.amazonaws.com/meditations/body-scan-10.mp3'),
('body-scan-15', 'Full body scan', '15 minutes of slow, detailed body scanning. Improves interoception so you read your own fatigue and recovery signals better.', 15, 'https://zealova-content.s3.amazonaws.com/meditations/body-scan-15.mp3'),
('breath-focus-5', 'Breath focus', '5 minutes of box breathing (4-4-4-4) — the simplest practice for resetting between meetings or before a hard set.', 5, 'https://zealova-content.s3.amazonaws.com/meditations/breath-focus-5.mp3'),
('breath-focus-8', 'Extended breath focus', '8 minutes of alternating box breath and physiological sigh patterns. Pairs well with afternoon energy dips.', 8, 'https://zealova-content.s3.amazonaws.com/meditations/breath-focus-8.mp3'),
('energy-boost-5', 'Morning energy boost', '5 minutes of energizing breath (longer inhales than exhales) and a clear intention for the day. Use within 30 min of waking.', 5, 'https://zealova-content.s3.amazonaws.com/meditations/energy-boost-5.mp3'),
('recovery-visualization-10', 'Recovery visualization', '10 minutes guiding you through visualizing repair, blood flow, and muscle recovery on rest days. Sounds woo, performs measurably better than scrolling.', 10, 'https://zealova-content.s3.amazonaws.com/meditations/recovery-visualization-10.mp3')
ON CONFLICT (slug) DO NOTHING;
