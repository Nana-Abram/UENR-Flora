-- Light hardening of the device_id trust model — run in the Supabase SQL
-- editor (after supabase/atomic_profile_updates.sql).
--
-- CONTEXT: this app has no auth layer (see the RLS note in
-- supabase/notifications.sql) — device_id is a client-supplied string, and
-- every table uses a permissive `USING (true)` RLS policy. That's a
-- deliberate, documented tradeoff for this project, not something this
-- migration tries to fully solve (the real fix is Supabase Anonymous Auth,
-- a much bigger change). What this migration DOES do is shrink the blast
-- radius of that tradeoff for user_profiles specifically:
--
--   1. Before this: `anon`/`authenticated` had a full table-level UPDATE
--      grant on user_profiles, so any caller with the (public) anon key
--      could PATCH total_points/streak_days/total_scans/etc. on ANY row to
--      ANY value directly via PostgREST, bypassing the app entirely.
--      After: those columns can only change through the three
--      `record_*_atomic` RPCs from atomic_profile_updates.sql (now marked
--      SECURITY DEFINER so they still work after the grant is narrowed),
--      which only ever apply fixed, well-defined increments. Direct column
--      grants are left in place for display_name/avatar_emoji, which
--      ProfileService.updateProfile() still needs for the name/emoji
--      editor.
--   2. record_challenge_completion_atomic no longer trusts a
--      client-supplied points number — it looks up the real
--      daily_challenges.points_reward for the given challenge instead, so
--      calling the RPC directly can no longer award arbitrary points.
--      (It still trusts the caller's p_is_correct flag; fully closing that
--      means validating the answer server-side too, which is really the
--      "idempotency guard" item's territory since both need a
--      server-side submit-and-check RPC — left as a follow-up there.)

ALTER FUNCTION record_scan_atomic(text, uuid, boolean)
  SECURITY DEFINER SET search_path = public;

ALTER FUNCTION record_article_read_atomic(text, int)
  SECURITY DEFINER SET search_path = public;

-- Signature change (points_earned -> challenge_id), so the old function
-- has to be dropped rather than replaced in place.
DROP FUNCTION IF EXISTS record_challenge_completion_atomic(text, boolean, int);

CREATE OR REPLACE FUNCTION record_challenge_completion_atomic(
  p_device_id text,
  p_challenge_id uuid,
  p_is_correct boolean
)
RETURNS user_profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_points_reward int;
  result user_profiles;
BEGIN
  SELECT points_reward INTO v_points_reward
  FROM daily_challenges WHERE id = p_challenge_id;

  IF v_points_reward IS NULL THEN
    RAISE EXCEPTION 'record_challenge_completion_atomic: no daily_challenges row for id %', p_challenge_id;
  END IF;

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
    total_points     = locked.total_points + (CASE WHEN p_is_correct THEN v_points_reward ELSE 0 END),
    level            = level_for_points(locked.total_points + (CASE WHEN p_is_correct THEN v_points_reward ELSE 0 END)),
    streak_days      = locked.new_streak,
    longest_streak   = GREATEST(locked.longest_streak, locked.new_streak),
    last_active_date = CURRENT_DATE,
    updated_at       = now()
  FROM locked
  WHERE up.device_id = locked.device_id
  RETURNING up.* INTO result;

  RETURN result;
END;
$$;

REVOKE UPDATE ON user_profiles FROM anon, authenticated;
GRANT UPDATE (display_name, avatar_emoji, updated_at) ON user_profiles TO anon, authenticated;
