-- Daily Challenge feature — run in the Supabase SQL editor.
--
-- NOTE: plant_species.id is a UUID (see lib/models/plant_species.dart /
-- identification_logs.predicted_species_id), not a BIGINT, so
-- daily_challenges.species_id is declared UUID below to match the FK target.

CREATE TABLE daily_challenges (
  id             UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  challenge_date DATE        UNIQUE NOT NULL,
  challenge_type TEXT        NOT NULL,
  -- types: 'identify_photo' | 'name_it' | 'find_it' |
  --        'true_false' | 'family_match'
  title          TEXT        NOT NULL,
  description    TEXT        NOT NULL,
  species_id     UUID        REFERENCES plant_species(id),
  question       TEXT        NOT NULL,
  options        JSONB,
  correct_answer TEXT        NOT NULL,
  points_reward  INTEGER     DEFAULT 50,
  fun_fact       TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE challenge_completions (
  id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id     TEXT        NOT NULL,
  challenge_id  UUID        REFERENCES daily_challenges(id),
  completed_at  TIMESTAMPTZ DEFAULT NOW(),
  points_earned INTEGER     DEFAULT 0,
  answer_given  TEXT,
  is_correct    BOOLEAN     DEFAULT FALSE,
  time_taken_s  INTEGER,
  UNIQUE(device_id, challenge_id)
);

ALTER TABLE challenge_completions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can insert" ON challenge_completions
  FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can read own" ON challenge_completions
  FOR SELECT USING (true);

ALTER TABLE daily_challenges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read" ON daily_challenges FOR SELECT USING (true);

-- Seed 7 days of challenges (species_id intentionally left NULL — these
-- questions don't reference a specific campus species row; set it manually
-- if you want the "View This Species" button to appear for a given day):
INSERT INTO daily_challenges
  (challenge_date, challenge_type, title, description, question,
   options, correct_answer, points_reward, fun_fact) VALUES

(CURRENT_DATE, 'true_false',
 'True or False?',
 'Test your knowledge of campus plants.',
 'Griffonia simplicifolia seeds — found right here on the UENR campus — contain up to 20% 5-HTP by weight, making Ghana''s the world''s primary supplier of this mental health supplement.',
 '["True", "False"]'::jsonb, 'True', 50,
 'Griffonia is the second most abundant species in the UENR bat sanctuary. Its seeds are exported globally for antidepressant supplements.'),

(CURRENT_DATE + 1, 'family_match',
 'Plant Family Match',
 'Match the plant to its family.',
 'Which plant family does Cassava (Manihot esculenta) belong to?',
 '["Fabaceae", "Euphorbiaceae", "Moraceae", "Poaceae"]'::jsonb,
 'Euphorbiaceae', 50,
 'Cassava shares its family with croton, castor oil plant, and copperleaf — all of which also grow on the UENR campus.'),

(CURRENT_DATE + 2, 'name_it',
 'What''s the Scientific Name?',
 'Prove you know your Latin.',
 'What is the scientific name of the Neem Tree?',
 '["Azadirachta indica", "Tectona grandis", "Moringa oleifera", "Gliricidia sepium"]'::jsonb,
 'Azadirachta indica', 50,
 'Neem is called Ghana''s village pharmacy — its bark, leaves, and seeds treat over 40 health conditions in traditional medicine.'),

(CURRENT_DATE + 3, 'true_false',
 'True or False?',
 'One of these facts about UENR trees is wrong. Which one is true?',
 'The Mast Tree (Monoon longifolium) was reclassified from the genus Polyalthia to Monoon following molecular studies in 2022.',
 '["True", "False"]'::jsonb, 'True', 50,
 'Scientific names can change as DNA analysis reveals new relationships between species. The Mast Tree''s reclassification is a recent example.'),

(CURRENT_DATE + 4, 'family_match',
 'Family or Imposter?',
 'Three of these belong to the same family. One does not.',
 'Which of these does NOT belong to the Fabaceae (legume) family?',
 '["Gliricidia sepium", "Griffonia simplicifolia", "Newbouldia laevis", "Millettia thonningii"]'::jsonb,
 'Newbouldia laevis', 50,
 'Newbouldia laevis belongs to Bignoniaceae — the same family as the African Tulip Tree. Gliricidia, Griffonia, and Millettia are all legumes.'),

(CURRENT_DATE + 5, 'name_it',
 'Common Name Challenge',
 'Can you identify the plant from its scientific name?',
 'What is the common name of Elaeis guineensis?',
 '["Coconut Palm", "African Oil Palm", "Manila Palm", "Date Palm"]'::jsonb,
 'African Oil Palm', 50,
 'Elaeis guineensis is native to West Africa — including Ghana. It produces more oil per hectare than any other crop on Earth.'),

(CURRENT_DATE + 6, 'true_false',
 'True or False?',
 'Think carefully about this one.',
 'The African Tulip Tree (Spathodea campanulata) is native to West Africa but is listed as one of the world''s 100 worst invasive species in other regions.',
 '["True", "False"]'::jsonb, 'True', 75,
 'A plant can be native and beneficial in one region while being invasive in another. Spathodea escapes cultivation so readily in Hawaii and the Pacific that it threatens native forest species there.');
