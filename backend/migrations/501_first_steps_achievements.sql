-- Migration 501: First Steps Achievements
-- Celebrates users' first key actions to boost Week 1 retention.
-- These are event-driven milestones (not threshold-based like workouts/streak).

-- ============================================
-- Insert First Steps Milestone Definitions
-- ============================================

INSERT INTO milestone_definitions (name, description, category, threshold, icon, tier, points, badge_color, share_message, sort_order) VALUES
('First Workout Warrior', 'Complete your first workout', 'first_steps', 1, 'fitness_center', 'bronze', 50, 'cyan', 'I just crushed my first workout with FitWiz!', 100),
('Snap Happy', 'Log your first meal with a photo', 'first_steps', 1, 'camera_alt', 'bronze', 30, 'green', 'Just logged my first meal photo with FitWiz!', 101),
('Scanner Pro', 'Use barcode scan for the first time', 'first_steps', 1, 'qr_code_scanner', 'bronze', 30, 'purple', 'Scanned my first barcode with FitWiz!', 102),
('Chat Started', 'Send your first message to AI coach', 'first_steps', 1, 'chat_bubble', 'bronze', 20, 'orange', 'Just started chatting with my AI coach on FitWiz!', 103),
('Week 1 Champion', 'Be active 5 or more days in your first week', 'first_steps', 5, 'emoji_events', 'silver', 100, 'gold', 'Week 1 Champion! Active 5+ days in my first week on FitWiz!', 104)
ON CONFLICT DO NOTHING;
