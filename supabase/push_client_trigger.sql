-- Fixes web push notifications never actually being delivered, even after
-- a device successfully subscribes: `send-daily-challenge-push` (see
-- web_push.sql) is a pg_cron job scheduled '0 7 * * *' that calls the
-- send-daily-challenge-push Edge Function via net.http_post. Checked
-- cron.job_run_details live — this job has fired exactly ONCE, ever
-- (2026-07-28 07:00), and never again since, despite many 07:00 UTC
-- crossings having happened since then. This is the same pg_cron
-- reliability problem already found and worked around for
-- ensure_daily_challenge() — see supabase/challenge_client_ensure.sql for
-- the full writeup. Same fix here: don't depend on the cron firing at all.
--
-- get_daily_push_targets() (in web_push.sql) is already idempotent per
-- device (WHERE ps.last_pushed_at IS NULL OR < CURRENT_DATE), so the
-- underlying Edge Function is safe to trigger redundantly from many
-- different devices throughout the day — each call just picks up whichever
-- eligible subscriptions haven't been pushed yet today, converging to a
-- no-op the more it's called.
CREATE OR REPLACE FUNCTION client_trigger_daily_push()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT net.http_post(
    url := 'https://sgeuuwwgjkwpiyatvtup.supabase.co/functions/v1/send-daily-challenge-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-function-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'push_function_secret')
    ),
    body := '{}'::jsonb
  );
$$;

-- Safe to expose: takes no arguments, and only ever triggers a send whose
-- own eligibility/idempotency logic lives server-side in
-- get_daily_push_targets() — a client can't use this to spam a specific
-- device or bypass the once-per-day-per-device limit.
GRANT EXECUTE ON FUNCTION client_trigger_daily_push() TO anon, authenticated;
