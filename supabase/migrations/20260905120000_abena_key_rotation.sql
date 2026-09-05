-- Tracks free-tier credit usage across multiple Abena TTS accounts so the
-- abena-tts edge function can rotate keys before one runs out, instead of
-- discovering exhaustion via a failed (slow) synthesis call.
CREATE TABLE IF NOT EXISTS abena_key_usage (
  key_index INT PRIMARY KEY,
  used_count INT NOT NULL DEFAULT 0,
  exhausted BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO abena_key_usage (key_index)
VALUES (1), (2), (3), (4), (5), (6)
ON CONFLICT (key_index) DO NOTHING;

-- Picks the lowest-indexed key that isn't exhausted and hasn't hit
-- usage_limit yet (kept below the real 50-credit cap as a safety margin).
-- Read-only: the edge function records success/exhaustion separately once it
-- knows the actual call outcome, so a transient timeout never burns budget.
CREATE OR REPLACE FUNCTION pick_abena_key(usage_limit INT DEFAULT 48)
RETURNS INT
LANGUAGE sql
STABLE
AS $$
  SELECT key_index FROM abena_key_usage
  WHERE NOT exhausted AND used_count < usage_limit
  ORDER BY key_index ASC
  LIMIT 1
$$;

CREATE OR REPLACE FUNCTION record_abena_key_success(idx INT)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE abena_key_usage SET used_count = used_count + 1, updated_at = now()
  WHERE key_index = idx
$$;

CREATE OR REPLACE FUNCTION mark_abena_key_exhausted(idx INT)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE abena_key_usage SET exhausted = true, updated_at = now()
  WHERE key_index = idx
$$;
