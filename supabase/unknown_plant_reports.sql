-- Backs the "Report Unknown Plant" button on UnknownPlantScreen (see
-- lib/features/scan/services/unknown_plant_reporter.dart) — a user-
-- confirmed "this genuinely isn't one of the 76 documented species" signal,
-- distinct from (and higher-signal than) the automatic OOD verdict every
-- such scan already gets via identification_logs.model_diagnostics (see
-- identification_logs_model_diagnostics.sql). Never read back by the app —
-- write-only from the client, same as identification_logs' note/
-- ai_analysis/model_diagnostics columns; intended for manual review and
-- future OodDetector threshold tuning (see that class's own doc comment).
--
-- closest_species/ood_distance/ood_threshold/raw_confidence/entropy/
-- tta_agreement/top3_probability/model_version all come straight from the
-- SAME diagnostics map logged to identification_logs.model_diagnostics for
-- this scan (see ScanDiagnostics.build) — kept numerically identical
-- between the two tables rather than recomputed, so a report and its
-- corresponding identification_logs row always agree.
CREATE TABLE IF NOT EXISTS unknown_plant_reports (
  id                   UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id            TEXT,
  location_description TEXT,
  notes                TEXT,
  image_url            TEXT,
  ood_distance         NUMERIC,
  ood_threshold        NUMERIC,
  closest_species      UUID        REFERENCES plant_species(id),
  raw_confidence       NUMERIC,
  entropy              NUMERIC,
  tta_agreement        INTEGER,
  top3_probability     NUMERIC,
  model_version        TEXT,
  created_at           TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE unknown_plant_reports ENABLE ROW LEVEL SECURITY;

-- Write-only from the client — no SELECT policy, matching the
-- user-submissions bucket's existing "Anon upload submissions" precedent
-- (insert-only, never read back by the anon/public role).
CREATE POLICY "Anyone can submit an unknown plant report"
  ON unknown_plant_reports FOR INSERT WITH CHECK (true);

-- Private bucket for the report's scan photo — never publicly readable
-- (no SELECT policy on storage.objects for this bucket_id), only the
-- anon-key client-side upload the app itself performs. image_url in the
-- table above stores the object's storage path, not a public URL — this
-- bucket has none; a reviewer needs a signed URL (or dashboard/service-role
-- access) to actually view an uploaded photo.
INSERT INTO storage.buckets (id, name, public)
VALUES ('unknown-plant-reports', 'unknown-plant-reports', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Anon upload unknown plant report photos"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'unknown-plant-reports');
