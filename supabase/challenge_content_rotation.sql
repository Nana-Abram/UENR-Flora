-- Fixes daily_challenges running out of content after 2026-07-09 — run in
-- the Supabase SQL editor (or `supabase db query --linked -f
-- supabase/challenge_content_rotation.sql`).
--
-- ROOT CAUSE: daily_challenges.sql seeded exactly 7 rows using
-- CURRENT_DATE/CURRENT_DATE+N *at the time that migration was run*
-- (2026-07-03), with no mechanism to ever add more. ChallengeService.
-- getTodaysChallenge() does `.eq('challenge_date', today)` — once "today"
-- moved past 2026-07-09, that query has returned null for every device,
-- every day, for weeks: no Challenge screen content, no in-app
-- "challenge_ready" reminder (NotificationProvider._checkDailyChallengeReminder
-- bails out on a null challenge), and no Web Push reminder either (the same
-- null check lives in get_daily_push_targets()'s JOIN). Just inserting a
-- few more dated rows by hand would only push the same dead end a few weeks
-- out — this fixes it so it can never run out again.
--
-- FIX: split the existing curated question content out of daily_challenges
-- (which stays exactly as the client already queries it — no Dart changes
-- needed) into a separate, date-less challenge_templates pool, then add a
-- SECURITY DEFINER function that inserts today's daily_challenges row from
-- that pool on demand (idempotent — a no-op if today's row already
-- exists), and a pg_cron job that calls it once daily so the row exists
-- before anyone/anything checks for it. The original 7 curated
-- UENR/Ghana-specific facts are the only content that exists to seed the
-- pool with — cycling through them roughly weekly is an honest tradeoff
-- (repeats > a permanently empty Challenge screen), and can be diluted by
-- inserting more rows into challenge_templates later without touching this
-- migration or any client code.
--
-- NOT touched: the 7 existing dated daily_challenges rows (2026-07-03..09)
-- stay exactly as-is — challenge_completions.challenge_id references them,
-- and getCompletionStreak() joins historical completions back to
-- daily_challenges.challenge_date, so deleting/rewriting them would corrupt
-- real devices' streak history.

CREATE TABLE IF NOT EXISTS challenge_templates (
  id             UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  sort_order     INT         NOT NULL,
  challenge_type TEXT        NOT NULL,
  title          TEXT        NOT NULL,
  description    TEXT        NOT NULL,
  species_id     UUID        REFERENCES plant_species(id),
  question       TEXT        NOT NULL,
  options        JSONB,
  correct_answer TEXT        NOT NULL,
  points_reward  INTEGER     DEFAULT 50,
  fun_fact       TEXT
);

-- Never queried by the client (getTodaysChallenge only reads
-- daily_challenges) — no RLS/grants needed beyond the default (no anon
-- access at all), same "server-only" treatment as push_subscriptions'
-- service_role-only surface.
ALTER TABLE challenge_templates ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON challenge_templates FROM anon, authenticated;

INSERT INTO challenge_templates
  (sort_order, challenge_type, title, description, question,
   options, correct_answer, points_reward, fun_fact) VALUES

(1, 'true_false', 'True or False?', 'Test your knowledge of campus plants.',
 'Griffonia simplicifolia seeds — found right here on the UENR campus — contain up to 20% 5-HTP by weight, making Ghana''s the world''s primary supplier of this mental health supplement.',
 '["True", "False"]'::jsonb, 'True', 50,
 'Griffonia is the second most abundant species in the UENR bat sanctuary. Its seeds are exported globally for antidepressant supplements.'),

(2, 'family_match', 'Plant Family Match', 'Match the plant to its family.',
 'Which plant family does Cassava (Manihot esculenta) belong to?',
 '["Fabaceae", "Euphorbiaceae", "Moraceae", "Poaceae"]'::jsonb,
 'Euphorbiaceae', 50,
 'Cassava shares its family with croton, castor oil plant, and copperleaf — all of which also grow on the UENR campus.'),

(3, 'name_it', 'What''s the Scientific Name?', 'Prove you know your Latin.',
 'What is the scientific name of the Neem Tree?',
 '["Azadirachta indica", "Tectona grandis", "Moringa oleifera", "Gliricidia sepium"]'::jsonb,
 'Azadirachta indica', 50,
 'Neem is called Ghana''s village pharmacy — its bark, leaves, and seeds treat over 40 health conditions in traditional medicine.'),

(4, 'true_false', 'True or False?', 'One of these facts about UENR trees is wrong. Which one is true?',
 'The Mast Tree (Monoon longifolium) was reclassified from the genus Polyalthia to Monoon following molecular studies in 2022.',
 '["True", "False"]'::jsonb, 'True', 50,
 'Scientific names can change as DNA analysis reveals new relationships between species. The Mast Tree''s reclassification is a recent example.'),

(5, 'family_match', 'Family or Imposter?', 'Three of these belong to the same family. One does not.',
 'Which of these does NOT belong to the Fabaceae (legume) family?',
 '["Gliricidia sepium", "Griffonia simplicifolia", "Newbouldia laevis", "Millettia thonningii"]'::jsonb,
 'Newbouldia laevis', 50,
 'Newbouldia laevis belongs to Bignoniaceae — the same family as the African Tulip Tree. Gliricidia, Griffonia, and Millettia are all legumes.'),

(6, 'name_it', 'Common Name Challenge', 'Can you identify the plant from its scientific name?',
 'What is the common name of Elaeis guineensis?',
 '["Coconut Palm", "African Oil Palm", "Manila Palm", "Date Palm"]'::jsonb,
 'African Oil Palm', 50,
 'Elaeis guineensis is native to West Africa — including Ghana. It produces more oil per hectare than any other crop on Earth.'),

(7, 'true_false', 'True or False?', 'Think carefully about this one.',
 'The African Tulip Tree (Spathodea campanulata) is native to West Africa but is listed as one of the world''s 100 worst invasive species in other regions.',
 '["True", "False"]'::jsonb, 'True', 75,
 'A plant can be native and beneficial in one region while being invasive in another. Spathodea escapes cultivation so readily in Hawaii and the Pacific that it threatens native forest species there.');

-- Idempotent: a no-op if daily_challenges already has a row for p_date.
-- Template selection is deterministic (based on the date itself, not
-- insertion order or random()), so calling this twice for the same date
-- — or out of order, e.g. backfilling a skipped day later — always picks
-- the same template rather than depending on when the function happened
-- to run.
CREATE OR REPLACE FUNCTION ensure_daily_challenge(p_date DATE DEFAULT CURRENT_DATE)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
  v_pool_size INT;
  v_offset INT;
  v_template challenge_templates%ROWTYPE;
BEGIN
  SELECT id INTO v_id FROM daily_challenges WHERE challenge_date = p_date;
  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;

  SELECT count(*) INTO v_pool_size FROM challenge_templates;
  IF v_pool_size = 0 THEN
    RETURN NULL;
  END IF;

  v_offset := (p_date - DATE '2026-01-01') % v_pool_size;
  SELECT * INTO v_template FROM challenge_templates ORDER BY sort_order OFFSET v_offset LIMIT 1;

  INSERT INTO daily_challenges
    (challenge_date, challenge_type, title, description, species_id,
     question, options, correct_answer, points_reward, fun_fact)
  VALUES
    (p_date, v_template.challenge_type, v_template.title, v_template.description,
     v_template.species_id, v_template.question, v_template.options,
     v_template.correct_answer, v_template.points_reward, v_template.fun_fact)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- Cron-only, like get_daily_push_targets() — pg_cron runs this directly
-- inside Postgres, not through PostgREST/the anon key, so it never needs a
-- REST-callable grant at all.
REVOKE EXECUTE ON FUNCTION ensure_daily_challenge(DATE) FROM PUBLIC, anon, authenticated;

-- Runs at 00:00 UTC (= 00:00 Ghana time, GMT year-round) — well before the
-- 07:00 send-daily-challenge-push job and before any campus device is
-- likely to open the Challenge screen, so today's row is always already
-- there by the time either checks for it.
SELECT cron.schedule(
  'ensure-daily-challenge',
  '0 0 * * *',
  $$SELECT ensure_daily_challenge(CURRENT_DATE);$$
);

-- Backfill today immediately rather than waiting for tomorrow's 00:00 run.
SELECT ensure_daily_challenge(CURRENT_DATE);
