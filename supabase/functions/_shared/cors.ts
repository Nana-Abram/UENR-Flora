// Shared CORS headers for edge functions called directly from the
// Flutter *web* app (as opposed to send-daily-challenge-push, which is
// cron-invoked server-side and never touches a browser). Every browser
// fetch to a different origin than the page it's running on — which a
// Supabase Edge Function always is — needs an OPTIONS preflight answered
// and these headers on the real response, or the browser blocks the
// call entirely before the app ever sees a result.
export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
