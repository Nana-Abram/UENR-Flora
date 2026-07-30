-- Fixes daily_challenges going stale again (2026-07-30): challenge_content_
-- rotation.sql's `ensure-daily-challenge` pg_cron job (0 0 * * *) was
-- created successfully and DID insert 2026-07-28's row via its manual
-- backfill call, but has not fired on its own schedule since — checked
-- `cron.job_run_details`, which shows exactly one run total across *both*
-- scheduled jobs on this project, ever. pg_cron's background launcher isn't
-- reliably running scheduled jobs on this project (small/low-traffic
-- projects can go idle between fixed-time triggers), the same class of
-- platform limitation as the storage Cache-Control issue — see
-- supabase-storage-cache-control-limitation in project memory.
--
-- FIX: don't depend on the cron firing at all. Add a client-callable
-- wrapper around the existing, already-idempotent ensure_daily_challenge()
-- and have ChallengeService call it right before reading today's row (see
-- lib/features/challenge/services/challenge_service.dart). Whichever user
-- opens the Challenge screen first each day creates the row on demand — the
-- cron job stays in place as a nice-to-have (it does still work sometimes),
-- this is just a client-side safety net so a real device is never blocked
-- on it.
CREATE OR REPLACE FUNCTION client_ensure_todays_challenge()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$ SELECT ensure_daily_challenge(CURRENT_DATE); $$;

-- Safe to expose: takes no arguments (always today, per the server clock),
-- and ensure_daily_challenge() is already idempotent — calling this from
-- every device on every page load does nothing after the first call of
-- the day.
GRANT EXECUTE ON FUNCTION client_ensure_todays_challenge() TO anon, authenticated;

-- Backfill immediately so the live site is fixed the moment this runs,
-- rather than waiting for the next client deploy.
SELECT client_ensure_todays_challenge();
