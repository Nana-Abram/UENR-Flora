-- Optional authored Twi narration. Existing species remain valid until content
-- is available; English narration remains synthesized from existing fields.
ALTER TABLE plant_species ADD COLUMN IF NOT EXISTS description_twi TEXT;