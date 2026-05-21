-- Migration 2087: Multi-day program-template importer (Phase B)
--
-- Adds the user-authored / library-imported / parsed multi-week program
-- template feature. All ALTERs on `workouts` and `user_program_assignments`
-- add NULLABLE columns with defaults => safe, non-blocking, no backfill
-- (per plan B.6 edge case #72).
--
-- Tables:
--   user_program_templates  - the template the user authors / imports / parses
--   user_program_schedules  - a scheduled instance (per-day times + alignment)
-- Columns added:
--   workouts.template_id / template_week / template_day_index / intensity_mode
--   user_program_assignments.template_id

-- ---------------------------------------------------------------------------
-- user_program_templates
-- ---------------------------------------------------------------------------
create table if not exists user_program_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  name text not null,
  description text,
  week_length int not null default 7,
  -- days: [{day_index, day_name, is_rest, workout_type, exercises:[
  --   {name, exercise_id, sets, reps_spec, target_rir, target_weight_kg,
  --    rest_seconds, notes, set_type, superset_group, per_side,
  --    unresolved, inferred}]}]
  days jsonb not null,
  deload_every_n_weeks int default 5,
  -- progression_strategy: linear | wave | double | none
  progression_strategy text not null default 'linear',
  -- inject the user's staple exercises into expanded workouts
  apply_staples boolean not null default true,
  -- source: authored | parsed | duplicated | library
  source text not null default 'authored',
  -- when source='library', the `programs` row it was cloned from
  source_program_id uuid,
  -- category carried from the `programs` row (Strength | Yoga | ...) - drives
  -- the default progression_strategy
  category text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_user_program_templates_user
  on user_program_templates(user_id);

-- ---------------------------------------------------------------------------
-- user_program_schedules - a scheduled instance of a template
-- ---------------------------------------------------------------------------
create table if not exists user_program_schedules (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null
    references user_program_templates(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  start_date date not null,
  weeks int not null,
  -- day_alignment: start_today | calendar_weekday
  day_alignment text not null default 'start_today',
  -- day_times: {"<day_index>": "06:30"} user-local time per training day;
  -- missing => 12:00 noon
  day_times jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists idx_user_program_schedules_template
  on user_program_schedules(template_id);
create index if not exists idx_user_program_schedules_user
  on user_program_schedules(user_id);

-- ---------------------------------------------------------------------------
-- workouts: link expanded workouts back to the template
-- ---------------------------------------------------------------------------
alter table workouts
  add column if not exists template_id uuid
    references user_program_templates(id) on delete set null;
alter table workouts
  add column if not exists template_week int;
alter table workouts
  add column if not exists template_day_index int;
-- intensity_mode: normal | deload  (used by the active-workout deload flow)
alter table workouts
  add column if not exists intensity_mode text;

create index if not exists idx_workouts_template
  on workouts(template_id, template_week, template_day_index);

-- Idempotency / concurrent-schedule guard (plan B.6 #39, #69):
-- a single template never produces two workouts for the same week+day+date.
create unique index if not exists uq_workouts_template_slot
  on workouts(template_id, template_week, template_day_index, scheduled_date)
  where template_id is not null;

-- ---------------------------------------------------------------------------
-- user_program_assignments: active template assignment
-- ---------------------------------------------------------------------------
alter table user_program_assignments
  add column if not exists template_id uuid
    references user_program_templates(id) on delete set null;
