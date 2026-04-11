-- Add "Walk After Eating" habit template
INSERT INTO habit_templates (name, description, category, habit_type, suggested_target, unit, icon, color, sort_order)
VALUES (
    'Walk After Eating',
    'Take a 10-15 min walk after meals to aid digestion',
    'activity',
    'positive',
    15,
    'minutes',
    'directions_walk',
    '#10B981',
    12
)
ON CONFLICT DO NOTHING;
