-- Additional botanical morphology fields for the background Claude
-- "second opinion" prompt (see BackgroundIdentifierService/SpeciesMetadata
-- and the background-identify edge function). Nullable — populated by a
-- one-time backfill, not required at insert time.
ALTER TABLE plant_species ADD COLUMN IF NOT EXISTS leaf_arrangement TEXT;
ALTER TABLE plant_species ADD COLUMN IF NOT EXISTS leaf_margin TEXT;
ALTER TABLE plant_species ADD COLUMN IF NOT EXISTS venation TEXT;
ALTER TABLE plant_species ADD COLUMN IF NOT EXISTS leaf_shape TEXT;
ALTER TABLE plant_species ADD COLUMN IF NOT EXISTS leaf_texture TEXT;
ALTER TABLE plant_species ADD COLUMN IF NOT EXISTS flower_description TEXT;
ALTER TABLE plant_species ADD COLUMN IF NOT EXISTS fruit_description TEXT;
ALTER TABLE plant_species ADD COLUMN IF NOT EXISTS bark_description TEXT;
