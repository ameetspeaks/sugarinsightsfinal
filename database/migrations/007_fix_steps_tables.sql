-- Fix Steps Tables to Match Existing Schema
-- This migration creates the steps tables with the comprehensive schema you already have

-- Drop existing tables if they exist (to avoid conflicts)
DROP TABLE IF EXISTS steps_readings CASCADE;
DROP TABLE IF EXISTS steps_goals CASCADE;

-- Create comprehensive steps_readings table
CREATE TABLE public.steps_readings (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  steps_count integer not null,
  distance_km numeric GENERATED ALWAYS as (((steps_count)::numeric * 0.0008)) STORED (5, 2) null,
  calories_burned integer GENERATED ALWAYS as (((steps_count)::numeric * 0.05)) STORED null,
  active_minutes integer GENERATED ALWAYS as ((steps_count / 100)) STORED null,
  activity_type character varying(20) null default 'walking'::character varying,
  source character varying(20) null default 'manual'::character varying,
  notes text null,
  reading_date date not null default CURRENT_DATE,
  reading_time time without time zone null default CURRENT_TIME,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint steps_readings_pkey primary key (id),
  constraint steps_readings_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE,
  constraint steps_readings_activity_type_check check (
    (
      (activity_type)::text = any (
        (
          array[
            'walking'::character varying,
            'running'::character varying,
            'hiking'::character varying,
            'cycling'::character varying,
            'swimming'::character varying,
            'other'::character varying
          ]
        )::text[]
      )
    )
  ),
  constraint steps_readings_source_check check (
    (
      (source)::text = any (
        (
          array[
            'manual'::character varying,
            'device'::character varying,
            'app'::character varying,
            'import'::character varying
          ]
        )::text[]
      )
    )
  ),
  constraint steps_readings_steps_count_check check (
    (
      (steps_count >= 0)
      and (steps_count <= 100000)
    )
  )
) TABLESPACE pg_default;

-- Create comprehensive steps_goals table
CREATE TABLE public.steps_goals (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  daily_goal integer not null default 10000,
  weekly_goal integer GENERATED ALWAYS as ((daily_goal * 7)) STORED null,
  monthly_goal integer GENERATED ALWAYS as ((daily_goal * 30)) STORED null,
  goal_type character varying(20) null default 'daily'::character varying,
  is_active boolean null default true,
  start_date date not null default CURRENT_DATE,
  end_date date null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint steps_goals_pkey primary key (id),
  constraint steps_goals_user_id_goal_type_start_date_key unique (user_id, goal_type, start_date),
  constraint steps_goals_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE,
  constraint steps_goals_daily_goal_check check (
    (
      (daily_goal > 0)
      and (daily_goal <= 100000)
    )
  ),
  constraint steps_goals_goal_type_check check (
    (
      (goal_type)::text = any (
        (
          array[
            'daily'::character varying,
            'weekly'::character varying,
            'monthly'::character varying,
            'custom'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;

-- Create indexes for better performance
CREATE INDEX IF not exists idx_steps_readings_user_id on public.steps_readings using btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF not exists idx_steps_readings_date on public.steps_readings using btree (reading_date) TABLESPACE pg_default;
CREATE INDEX IF not exists idx_steps_readings_activity_type on public.steps_readings using btree (activity_type) TABLESPACE pg_default;
CREATE INDEX IF not exists idx_steps_readings_user_date on public.steps_readings using btree (user_id, reading_date) TABLESPACE pg_default;

CREATE INDEX IF not exists idx_steps_goals_user_id on public.steps_goals using btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF not exists idx_steps_goals_active on public.steps_goals using btree (is_active) TABLESPACE pg_default;

-- Create trigger functions if they don't exist
CREATE OR REPLACE FUNCTION update_steps_readings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_steps_goals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_steps_readings_updated_at 
    BEFORE UPDATE ON steps_readings 
    FOR EACH ROW 
    EXECUTE FUNCTION update_steps_readings_updated_at();

CREATE TRIGGER update_steps_goals_updated_at 
    BEFORE UPDATE ON steps_goals 
    FOR EACH ROW 
    EXECUTE FUNCTION update_steps_goals_updated_at();

-- Enable Row Level Security
ALTER TABLE steps_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE steps_goals ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for steps_readings
CREATE POLICY "Users can view own steps readings" ON steps_readings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own steps readings" ON steps_readings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own steps readings" ON steps_readings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own steps readings" ON steps_readings
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for steps_goals
CREATE POLICY "Users can view own steps goals" ON steps_goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own steps goals" ON steps_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own steps goals" ON steps_goals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own steps goals" ON steps_goals
    FOR DELETE USING (auth.uid() = user_id);

-- Grant necessary permissions
GRANT ALL ON steps_readings TO authenticated;
GRANT ALL ON steps_goals TO authenticated;
GRANT ALL ON steps_readings TO anon;
GRANT ALL ON steps_goals TO anon;

-- Success message
SELECT 'Steps tables created successfully with comprehensive schema!' as status; 