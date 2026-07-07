-- Profile & achievements feature — run in the Supabase SQL editor
-- (after supabase/daily_challenges.sql).
--
-- NOTES on JSONB column contents:
--   species_found  — array of plant_species.id UUID strings
--   articles_read  — array of learn_articles.id integers
--
-- identification_logs previously had no device scoping (it only powered
-- app-wide dashboard stats). The Profile feature's "Recent Activity" list
-- and scan-count achievements need to know which scans belong to which
-- device, so we add a nullable device_id column here — existing rows are
-- left with a null device_id and simply won't show up in anyone's history.

CREATE TABLE user_profiles (
  device_id          TEXT        PRIMARY KEY,
  display_name       TEXT        DEFAULT 'Plant Explorer',
  avatar_emoji       TEXT        DEFAULT '🌱',
  total_points       INTEGER     DEFAULT 0,
  level              INTEGER     DEFAULT 1,
  streak_days        INTEGER     DEFAULT 0,
  longest_streak     INTEGER     DEFAULT 0,
  last_active_date   DATE,
  total_scans        INTEGER     DEFAULT 0,
  total_correct      INTEGER     DEFAULT 0,
  total_challenges   INTEGER     DEFAULT 0,
  species_found      JSONB       DEFAULT '[]'::jsonb,
  articles_read      JSONB       DEFAULT '[]'::jsonb,
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  updated_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_achievements (
  id             UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id      TEXT    REFERENCES user_profiles(device_id),
  achievement_id TEXT    NOT NULL,
  unlocked_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(device_id, achievement_id)
);

ALTER TABLE user_profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can manage own profile"
  ON user_profiles FOR ALL USING (true);
CREATE POLICY "Anyone can manage own achievements"
  ON user_achievements FOR ALL USING (true);

ALTER TABLE identification_logs ADD COLUMN IF NOT EXISTS device_id TEXT;
