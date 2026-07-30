-- Dashboard aggregate RPCs — run in the Supabase SQL editor.
--
-- DashboardProvider used to call SpeciesRepository.getScanLogs(), which
-- fetched every row of identification_logs (created_at, health_status,
-- predicted_species_id, confidence_score) on every app load and every
-- reload() after a scan — unbounded, and only getting bigger over the
-- app's lifetime, just to compute a handful of all-time totals plus a
-- chart that only needs recent history.
--
-- These two functions push the all-time aggregates (total scan count,
-- healthy/unhealthy counts, per-species average confidence) into Postgres,
-- which can compute them over the whole table cheaply without shipping
-- every row to the client. The chart data (daily/weekly/monthly buckets)
-- still needs raw per-row timestamps to bucket client-side, but only ever
-- needs recent history — see SpeciesRepository.getScanTimestampsSinceYearStart.

CREATE OR REPLACE FUNCTION dashboard_totals()
RETURNS TABLE (total_scans bigint, healthy_count bigint, unhealthy_count bigint)
LANGUAGE sql
STABLE
AS $$
  SELECT
    COUNT(*) AS total_scans,
    COUNT(*) FILTER (WHERE health_status = 'healthy') AS healthy_count,
    COUNT(*) FILTER (WHERE health_status = 'unhealthy') AS unhealthy_count
  FROM identification_logs;
$$;

CREATE OR REPLACE FUNCTION species_avg_confidence()
RETURNS TABLE (species_id uuid, avg_confidence double precision)
LANGUAGE sql
STABLE
AS $$
  SELECT predicted_species_id AS species_id, AVG(confidence_score) AS avg_confidence
  FROM identification_logs
  WHERE predicted_species_id IS NOT NULL AND confidence_score IS NOT NULL
  GROUP BY predicted_species_id;
$$;
