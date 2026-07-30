-- Opt-in leaderboard — run in the Supabase SQL editor.
--
-- Ranking is only ever exposed through the two RPCs below, both
-- SECURITY DEFINER — the client never gets a raw SELECT on user_profiles
-- for this feature, and neither RPC's return type includes device_id.
-- get_leaderboard() only reads leaderboard_opt_in = true rows in the first
-- place, and get_my_leaderboard_rank() takes the caller's own device_id as
-- a parameter (already how every other per-device RPC in this project
-- works — see atomic_profile_updates.sql) purely to look up *that* row's
-- rank, never to hand back anyone else's id.
--
-- Defaulting leaderboard_opt_in to false is the actual privacy boundary
-- here: a device's total_points/display_name/avatar are already readable
-- by any anon-key caller today (see the no-auth tradeoff documented in
-- harden_profile_writes.sql) — this migration doesn't change that — but
-- without this flag, EVERY device would show up on a public ranking by
-- default the moment this feature shipped, which is a materially
-- different (and worse) exposure than "readable if you already knew to
-- look," and not something a device agreed to.

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS leaderboard_opt_in BOOLEAN NOT NULL DEFAULT FALSE;

-- Matches the harden_profile_writes.sql pattern exactly: narrow, additive
-- column grant, not a broader UPDATE reopen.
GRANT UPDATE (leaderboard_opt_in) ON user_profiles TO anon, authenticated;

CREATE OR REPLACE FUNCTION get_leaderboard(p_limit int DEFAULT 20)
RETURNS TABLE(rank bigint, display_name text, avatar_emoji text, total_points int, level int)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    RANK() OVER (ORDER BY up.total_points DESC) AS rank,
    up.display_name,
    up.avatar_emoji,
    up.total_points,
    up.level
  FROM user_profiles up
  WHERE up.leaderboard_opt_in = true
  ORDER BY up.total_points DESC
  LIMIT p_limit;
$$;

-- Separate from get_leaderboard() because the caller's own rank might be
-- well outside whatever LIMIT the visible list uses (e.g. rank #340) —
-- this answers "where do I stand" without requiring the client to fetch
-- the entire table to find itself.
CREATE OR REPLACE FUNCTION get_my_leaderboard_rank(p_device_id text)
RETURNS TABLE(opted_in boolean, rank bigint, total_points int, out_of bigint)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_opted_in boolean;
  v_points int;
  v_out_of bigint;
BEGIN
  SELECT up.leaderboard_opt_in, up.total_points INTO v_opted_in, v_points
  FROM user_profiles up WHERE up.device_id = p_device_id;

  SELECT COUNT(*) INTO v_out_of FROM user_profiles up WHERE up.leaderboard_opt_in = true;

  IF v_opted_in IS NOT TRUE THEN
    RETURN QUERY SELECT false, NULL::bigint, COALESCE(v_points, 0), v_out_of;
    RETURN;
  END IF;

  RETURN QUERY
  SELECT true, ranked.rank, v_points, v_out_of
  FROM (
    SELECT RANK() OVER (ORDER BY up.total_points DESC) AS rank, up.device_id
    FROM user_profiles up
    WHERE up.leaderboard_opt_in = true
  ) ranked
  WHERE ranked.device_id = p_device_id;
END;
$$;

GRANT EXECUTE ON FUNCTION get_leaderboard(int) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_my_leaderboard_rank(text) TO anon, authenticated;
