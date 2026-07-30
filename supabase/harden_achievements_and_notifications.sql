-- Follow-up to harden_profile_writes.sql — closes gaps that migration missed.
-- Run in the Supabase SQL editor (after harden_profile_writes.sql).
--
-- Audited live grants/policies on sgeuuwwgjkwpiyatvtup (UENR_Flora) with
-- `supabase db query --linked` against pg_policies/information_schema.
-- Findings, in order of severity:
--
--   1. user_achievements had RLS policy "FOR ALL USING (true)" plus full
--      anon/authenticated grants — meaning any caller with the (public)
--      anon key could:
--        - INSERT any achievement_id for any device_id, instantly
--          "unlocking" an achievement without ever meeting its condition
--          (the eligibility check in ProfileService.checkAndUnlockAchievements
--          is pure client-side Dart with nothing server-side re-validating
--          it before the insert), or
--        - DELETE another device's achievement rows outright.
--      The app itself only ever SELECTs and INSERTs this table (see
--      getUnlockedAchievements/getUnlockDates/checkAndUnlockAchievements in
--      profile_service.dart) — it never updates or deletes a row. Revoking
--      UPDATE/DELETE below is a pure grant-narrowing with zero behavior
--      change, same treatment harden_profile_writes.sql already gave
--      user_profiles.
--      NOT fully closed by this migration: INSERT still trusts the client's
--      claim that an achievement was earned. Fully closing that needs an
--      `unlock_achievement_atomic(p_device_id, p_achievement_id)` SECURITY
--      DEFINER RPC that re-derives the same eligibility conditions
--      server-side (mirroring how record_challenge_completion_atomic
--      re-derives points_reward instead of trusting a client-supplied
--      number) — a real code change, left as a follow-up rather than done
--      here.
--
--   2. user_profiles DELETE was never narrowed by harden_profile_writes.sql
--      (only UPDATE was) — RLS is "FOR ALL", so an unrestricted DELETE
--      grant let any anon caller delete ANY device's profile row directly,
--      bypassing resetProfile()/reset_profile_atomic entirely. The app
--      never deletes a user_profiles row itself (reset goes through the
--      atomic RPC, which is SECURITY DEFINER and unaffected by revoking the
--      table-level grant). Revoking below closes a pure griefing vector.
--
--   3. notifications had an UPDATE policy ("Anyone can update
--      notifications", USING (true), no WITH CHECK) plus a full-column
--      UPDATE grant — intentionally permissive per the no-auth design note
--      in notifications.sql, but broader than the app needs:
--      NotificationService only ever flips is_read via
--      markAsRead/markAllAsRead, never touches title/body/type/device_id/
--      action_route. A WITH CHECK alone does NOT close this — it only
--      constrains the *resulting* row, so once is_read is already true (the
--      state after the very first legitimate markAsRead), a later PATCH
--      touching only `title` leaves is_read unchanged at true and sails
--      through the check while still overwriting the title. Verified this
--      live: a WITH CHECK (is_read = true) policy let a same-session PATCH
--      rewrite `title` to "defaced" once is_read was true. The actual fix
--      is a column-level GRANT (the same mechanism harden_profile_writes.sql
--      already uses for user_profiles.display_name/avatar_emoji) — it
--      restricts which columns are legal in the UPDATE's SET list at all,
--      independent of row content. This keeps the existing "no device
--      ownership check" tradeoff (still documented/accepted — closing that
--      needs real auth) while preventing content tampering/spoofing of
--      other devices' notification text.
--
--   Not exploitable despite noisy-looking grants (documented for the next
--   person who runs the same grant audit and gets confused): daily_challenges
--   and challenge_completions both have UPDATE/DELETE table-level grants
--   left over from Supabase's default anon/authenticated privileges, but
--   RLS on both tables only defines SELECT (+ INSERT for
--   challenge_completions) policies — with no UPDATE/DELETE policy, RLS
--   denies those commands outright regardless of the table grant. Same for
--   identification_logs. Left as-is; revoking the dead grants would be
--   cosmetic since RLS already blocks them.

REVOKE UPDATE, DELETE ON user_achievements FROM anon, authenticated;
REVOKE DELETE ON user_profiles FROM anon, authenticated;

DROP POLICY IF EXISTS "Anyone can update notifications" ON notifications;
CREATE POLICY "Anyone can mark notifications read"
  ON notifications FOR UPDATE
  USING (true)
  WITH CHECK (is_read = true);

REVOKE UPDATE ON notifications FROM anon, authenticated;
GRANT UPDATE (is_read) ON notifications TO anon, authenticated;
