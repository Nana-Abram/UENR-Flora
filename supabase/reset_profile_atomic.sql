-- Atomic profile reset — run in the Supabase SQL editor.
--
-- ProfileService.resetProfile used to run two separate DELETE statements
-- (user_achievements, then user_profiles, in that FK-mandated order). If
-- the second delete failed after the first succeeded, a device was left
-- with its achievements wiped but its profile intact — a silent partial
-- reset. Wrapping both in one function means Postgres runs them in a
-- single transaction: either both rows are gone or neither is.

CREATE OR REPLACE FUNCTION reset_profile_atomic(p_device_id text)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM user_achievements WHERE device_id = p_device_id;
  DELETE FROM user_profiles WHERE device_id = p_device_id;
END;
$$;
