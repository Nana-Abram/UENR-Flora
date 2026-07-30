-- Adds a free-text note column to identification_logs so a rejected
-- "not a plant" scan can be recorded distinctly from a real (if low-
-- confidence) identification, instead of either being silently dropped or
-- polluting the confidence/species stats with a 0%-confidence non-plant
-- guess. Nullable — every existing/normal identification leaves this null.
ALTER TABLE identification_logs ADD COLUMN IF NOT EXISTS note TEXT;
