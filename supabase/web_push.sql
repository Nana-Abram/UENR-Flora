-- Web Push for daily-challenge notifications — run in the Supabase SQL editor
-- (or `supabase db query --linked -f supabase/web_push.sql`).
--
-- Trust model matches every other table in this project (see the note atop
-- notifications.sql): no auth layer, anon key talks to Postgres directly,
-- permissive `USING (true)` policies with column/command-level grants doing
-- the narrowing instead of ownership checks. push_subscriptions only needs
-- INSERT (register) and DELETE (unsubscribe) from the client — never SELECT
-- or UPDATE, since the client always knows its own subscription state
-- locally via the browser's PushManager.getSubscription(), so it never needs
-- to read this table back. The send-daily-challenge-push Edge Function
-- reads/writes it with the service_role key, which bypasses RLS entirely.

CREATE TABLE IF NOT EXISTS push_subscriptions (
  id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id     TEXT        NOT NULL,
  endpoint      TEXT        NOT NULL UNIQUE,
  p256dh        TEXT        NOT NULL,
  auth          TEXT        NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  last_pushed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS push_subscriptions_device_id_idx ON push_subscriptions (device_id);

ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can register a push subscription" ON push_subscriptions;
CREATE POLICY "Anyone can register a push subscription"
  ON push_subscriptions FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can remove a push subscription" ON push_subscriptions;
CREATE POLICY "Anyone can remove a push subscription"
  ON push_subscriptions FOR DELETE USING (true);

GRANT INSERT, DELETE ON push_subscriptions TO anon, authenticated;
-- Deliberately no SELECT/UPDATE grant to anon/authenticated — see note above.
GRANT SELECT, UPDATE, DELETE ON push_subscriptions TO service_role;

-- Eligibility logic lives here (not duplicated in the Edge Function's own
-- query-building) so it stays in lockstep with ChallengeService's client-side
-- hasCompletedToday(): a device is due for today's push iff it has a
-- subscription, today's challenge exists, it hasn't completed it yet, and it
-- hasn't already been pushed today (idempotent against the cron job firing
-- more than once, or a manual re-run). SECURITY DEFINER + service_role-only
-- EXECUTE because the result set includes push subscription keys — the same
-- reasoning get_leaderboard/get_my_leaderboard_rank use for device_id, just
-- inverted (this one is deliberately NOT anon-callable at all).
CREATE OR REPLACE FUNCTION get_daily_push_targets()
RETURNS TABLE(subscription_id UUID, device_id TEXT, endpoint TEXT, p256dh TEXT, auth TEXT)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT ps.id, ps.device_id, ps.endpoint, ps.p256dh, ps.auth
  FROM push_subscriptions ps
  JOIN daily_challenges dc ON dc.challenge_date = CURRENT_DATE
  WHERE NOT EXISTS (
    SELECT 1 FROM challenge_completions cc
    WHERE cc.device_id = ps.device_id AND cc.challenge_id = dc.id
  )
  AND (ps.last_pushed_at IS NULL OR ps.last_pushed_at < CURRENT_DATE);
$$;

REVOKE EXECUTE ON FUNCTION get_daily_push_targets() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION get_daily_push_targets() TO service_role;

-- ─────────────────────────────────────────────────────────────
-- Scheduling: pg_cron calls the Edge Function once daily via pg_net, exactly
-- the way Supabase's own docs recommend for cron-driven Edge Functions
-- (there is no built-in "invoke this function on a schedule" primitive
-- otherwise). The function itself re-derives who's eligible (has a
-- subscription, hasn't completed today's challenge, hasn't already been
-- pushed today) — this job's only responsibility is firing it.
-- ─────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

GRANT USAGE ON SCHEMA cron TO postgres;
GRANT USAGE ON SCHEMA net TO postgres;

-- The function is deployed with --no-verify-jwt (Supabase Auth JWTs don't
-- apply here — nothing in this app authenticates), so it's reachable by
-- anyone who knows the URL. It re-checks this shared secret itself before
-- doing anything, closing that off. Stored in Vault rather than a plain
-- GUC so it never appears in `pg_settings`/logs/pg_dump output in plaintext.
-- Generate a fresh value for this (e.g. `openssl rand -base64 32` or
-- `node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"`)
-- rather than reusing whatever was here before — this file is checked into
-- git, so the real secret must never be committed in plaintext. It's
-- already live in Vault on the deployed project; re-running this file
-- as-is would just rotate it to a new (also-placeholder) value, which is
-- harmless but means updating PUSH_FUNCTION_SECRET via `supabase secrets
-- set` to match — see README/deploy notes.
SELECT vault.create_secret(
  'REPLACE_WITH_FRESH_RANDOM_SECRET',
  'push_function_secret',
  'Shared secret the daily push cron job sends to the send-daily-challenge-push Edge Function'
);

-- Runs at 07:00 UTC, which is also 07:00 Ghana time (GMT year-round, no
-- DST) — matching the "past 7am local time" reminder threshold the in-app
-- NotificationProvider._checkDailyChallengeReminder already uses.
SELECT cron.schedule(
  'send-daily-challenge-push',
  '0 7 * * *',
  $$
  SELECT net.http_post(
    url := 'https://sgeuuwwgjkwpiyatvtup.supabase.co/functions/v1/send-daily-challenge-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-function-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'push_function_secret')
    ),
    body := '{}'::jsonb
  );
  $$
);
