-- Atomic profile-update RPCs — run in the Supabase SQL editor
-- (after supabase/user_profiles.sql and supabase/daily_challenges.sql).
--
-- WHY THIS EXISTS:
-- ProfileService.recordScan / recordArticleRead / recordChallengeCompletion
-- used to read the profile row into Dart, compute the new totals there, then
-- write them back. Two concurrent calls for the same device_id (a
-- double-click, a retried request, two open tabs) could both read the same
-- total_points/streak_days and the second write would silently clobber the
-- first — a classic lost-update race. Each function below folds the whole
-- read-modify-write into one statement that Postgres executes under a
-- single row lock, so concurrent calls serialize instead of racing.
--
-- These assume the user_profiles row already exists — ProfileService still
-- calls getOrCreateProfile() first, same as before.

CREATE OR REPLACE FUNCTION level_for_points(points int)
RETURNS int
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN points >= 2000 THEN 5
    WHEN points >= 1000 THEN 4
    WHEN points >= 500  THEN 3
    WHEN points >= 200  THEN 2
    ELSE 1
  END;
$$;

-- Mirrors ProfileService.recordScan. p_species_id is NULL when the scan
-- didn't confidently match a species; p_is_correct mirrors the old
-- `isCorrect` flag gating whether it counts toward species_found.
CREATE OR REPLACE FUNCTION record_scan_atomic(
  p_device_id text,
  p_species_id uuid,
  p_is_correct boolean
)
RETURNS user_profiles
LANGUAGE sql
AS $$
  UPDATE user_profiles
  SET
    total_scans = total_scans + 1,
    species_found = CASE
      WHEN p_is_correct AND p_species_id IS NOT NULL
           AND NOT (species_found @> to_jsonb(p_species_id::text))
      THEN species_found || to_jsonb(p_species_id::text)
      ELSE species_found
    END,
    last_active_date = CURRENT_DATE,
    updated_at = now()
  WHERE device_id = p_device_id
  RETURNING *;
$$;

-- Mirrors ProfileService.recordArticleRead's "only add once" behavior.
CREATE OR REPLACE FUNCTION record_article_read_atomic(
  p_device_id text,
  p_article_id int
)
RETURNS user_profiles
LANGUAGE sql
AS $$
  UPDATE user_profiles
  SET
    articles_read = CASE
      WHEN NOT (articles_read @> to_jsonb(p_article_id))
      THEN articles_read || to_jsonb(p_article_id)
      ELSE articles_read
    END,
    last_active_date = CURRENT_DATE,
    updated_at = now()
  WHERE device_id = p_device_id
  RETURNING *;
$$;

-- Mirrors ProfileService.recordChallengeCompletion's streak math exactly
-- (same "consecutive day" / "same day" / "gap or first time" cases), but
-- computed once in a locked CTE (`FOR UPDATE`) instead of twice in Dart.
CREATE OR REPLACE FUNCTION record_challenge_completion_atomic(
  p_device_id text,
  p_is_correct boolean,
  p_points_earned int
)
RETURNS user_profiles
LANGUAGE sql
AS $$
  WITH locked AS (
    SELECT
      up.*,
      CASE
        WHEN NOT p_is_correct THEN 0
        WHEN up.last_active_date IS NULL THEN 1
        WHEN up.last_active_date = CURRENT_DATE - 1 THEN up.streak_days + 1
        WHEN up.last_active_date = CURRENT_DATE THEN up.streak_days
        ELSE 1
      END AS new_streak
    FROM user_profiles up
    WHERE up.device_id = p_device_id
    FOR UPDATE
  )
  UPDATE user_profiles up
  SET
    total_challenges = locked.total_challenges + 1,
    total_correct    = locked.total_correct + (CASE WHEN p_is_correct THEN 1 ELSE 0 END),
    total_points     = locked.total_points + p_points_earned,
    level            = level_for_points(locked.total_points + p_points_earned),
    streak_days      = locked.new_streak,
    longest_streak   = GREATEST(locked.longest_streak, locked.new_streak),
    last_active_date = CURRENT_DATE,
    updated_at       = now()
  FROM locked
  WHERE up.device_id = locked.device_id
  RETURNING up.*;
$$;
