// Sends today's daily-challenge Web Push reminder to every device that's
// subscribed and hasn't completed (or already been reminded about) today's
// challenge yet. Invoked daily by the `send-daily-challenge-push` pg_cron
// job (see supabase/web_push.sql) — not reachable by the app's own anon key,
// only by whoever holds `x-push-function-secret` (the cron job, via Vault).
//
// Deployed with --no-verify-jwt: nothing in this app authenticates via
// Supabase Auth, so the platform's own JWT check doesn't apply here — the
// shared-secret header below is what actually gates this endpoint.
import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY")!;
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY")!;
const VAPID_SUBJECT = Deno.env.get("VAPID_SUBJECT") ?? "mailto:uenrflora@gmail.com";
const PUSH_FUNCTION_SECRET = Deno.env.get("PUSH_FUNCTION_SECRET")!;

webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);

interface PushTarget {
  subscription_id: string;
  device_id: string;
  endpoint: string;
  p256dh: string;
  auth: string;
}

// One malformed/corrupt subscription must never take down the whole daily
// run for every other device — Promise.allSettled (not Promise.all) plus a
// per-item try/catch means a single bad row can only ever count itself as
// failed, never reject the batch. The outer try/catch is a second layer for
// anything upstream of the per-item loop (e.g. the RPC call itself).
Deno.serve(async (req) => {
  try {
    if (req.headers.get("x-push-function-secret") !== PUSH_FUNCTION_SECRET) {
      return new Response("Forbidden", { status: 403 });
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data: targets, error } = await supabase.rpc("get_daily_push_targets");
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const payload = JSON.stringify({
      title: "Daily Challenge Available",
      body: "Test your plant knowledge and earn points. Today's challenge is ready!",
      url: "/challenge",
      iconEmoji: "🎯",
    });

    let sent = 0;
    let pruned = 0;
    let failed = 0;

    await Promise.allSettled(
      ((targets ?? []) as PushTarget[]).map(async (t) => {
        try {
          await webpush.sendNotification(
            { endpoint: t.endpoint, keys: { p256dh: t.p256dh, auth: t.auth } },
            payload,
          );
          await supabase
            .from("push_subscriptions")
            .update({ last_pushed_at: new Date().toISOString() })
            .eq("id", t.subscription_id);
          sent++;
        } catch (err) {
          // 404/410 = the browser/OS push service has permanently
          // invalidated this subscription (uninstalled, permission revoked,
          // endpoint rotated past its lifetime) — every future send would
          // fail the same way, so prune it instead of retrying it forever.
          const status = (err as { statusCode?: number })?.statusCode;
          if (status === 404 || status === 410) {
            await supabase.from("push_subscriptions").delete().eq("id", t.subscription_id);
            pruned++;
          } else {
            failed++;
            console.error(`push failed for subscription ${t.subscription_id}:`, err);
          }
        }
      }),
    );

    return new Response(
      JSON.stringify({ targeted: targets?.length ?? 0, sent, pruned, failed }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("send-daily-challenge-push crashed:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
