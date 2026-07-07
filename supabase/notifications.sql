-- In-app notifications feature — run in the Supabase SQL editor.
--
-- RLS NOTE: the spec's policies use current_setting('app.device_id', true),
-- which only works if something sets that Postgres session variable per
-- request (e.g. a custom server-side session/JWT claim). This app has no
-- auth layer and talks to Supabase directly with the anon key from the
-- browser, so there is no session to scope to — every other table in this
-- project (user_profiles, user_achievements, daily_challenges, ...) uses a
-- permissive `USING (true)` policy and filters by device_id in application
-- code instead. Notifications follow the same pattern here, including on
-- INSERT: createNotification() is called directly from the Flutter client
-- (e.g. when an achievement unlocks), not from a trusted backend, so an
-- "insert: service role only" policy would just break that call.

CREATE TABLE notifications (
  id           UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id    TEXT,       -- NULL means notification is for all users
  title        TEXT        NOT NULL,
  body         TEXT        NOT NULL,
  type         TEXT        NOT NULL,
  -- types: 'challenge_ready' | 'streak_warning' | 'achievement'
  --      | 'new_article' | 'new_species' | 'tip' | 'system'
  icon_emoji   TEXT        DEFAULT '🔔',
  action_route TEXT,       -- e.g. '/challenge' or '/learn/article/5'
  is_read      BOOLEAN     DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  expires_at   TIMESTAMPTZ -- optional, hide after this date
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read own and broadcast notifications"
  ON notifications FOR SELECT USING (true);
CREATE POLICY "Anyone can update notifications"
  ON notifications FOR UPDATE USING (true);
CREATE POLICY "Anyone can insert notifications"
  ON notifications FOR INSERT WITH CHECK (true);

-- Seed some global broadcast notifications:
INSERT INTO notifications (device_id, title, body, type, icon_emoji, action_route) VALUES
(NULL, 'Welcome to UENR Flora!',
 'Start by scanning a plant on campus. Each scan helps build our biodiversity record.',
 'system', '🌱', '/scan'),

(NULL, 'Daily Challenge Available',
 'Test your plant knowledge and earn points. New challenge every day at 7am.',
 'challenge_ready', '🎯', '/challenge'),

(NULL, 'Did You Know?',
 'The UENR bat sanctuary contains 58 documented plant species across 25 families — explore them in the Species Explorer.',
 'tip', '🦇', '/explorer'),

(NULL, 'Learn Something New',
 'Check out our article on Ghana''s Village Pharmacy — 8 medicinal trees growing right here on campus.',
 'new_article', '📚', '/learn');
