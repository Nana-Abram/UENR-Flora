-- Stores the background Claude "second opinion" layer's verdict (see
-- lib/features/scan/services/background_identifier_service.dart)
-- alongside the identification it ran against, for QA/analytics only —
-- never read back by the app, never shown to any user. Null whenever the
-- activation rule didn't fire (local prediction was clearly confident and
-- unambiguous — see BackgroundIdentifierService.shouldActivate) or the
-- background call itself failed (network error, timeout, malformed
-- response — see BackgroundIdentificationResult.toLogJson).
ALTER TABLE identification_logs ADD COLUMN IF NOT EXISTS ai_analysis JSONB;
